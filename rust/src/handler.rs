//! 對話狀態機（對應 aws/lambda/message_handler.rb 與 test_handler.rb）。
//!
//! `handle` 只負責「收到一則文字 → 算出要回的訊息並更新狀態」，
//! 真正呼叫 LINE reply API 由呼叫端（server）處理，方便測試。

use serde_json::{json, Map, Value};

use crate::calculator;
use crate::fields::{self, FIELDS};
use crate::flex;
use crate::store::{Form, State, Store};

pub fn handle(store: &Store, user_id: &str, text: &str, now: i64) -> Value {
    // 測試指令：不讀寫狀態
    if text == "test" {
        return test_response();
    }

    let mut state = match store.get_state(user_id, now) {
        Ok(Some(s)) => s,
        Ok(None) => State::default(),
        Err(e) => {
            eprintln!("Store get_state error: {e}");
            State::default()
        }
    };
    state.user_id.get_or_insert_with(|| user_id.to_string());

    let response = process_message(store, text, &mut state, now);

    if let Err(e) = store.save_state(user_id, &state, now) {
        eprintln!("Store save_state error: {e}");
    }
    response
}

fn start(state: &mut State) -> Value {
    state.form = Form { params: Map::new(), waiting_for: Some(FIELDS[0].key.to_string()) };
    FIELDS[0].prompt()
}

fn text_message(text: &str) -> Value {
    json!({ "type": "text", "text": text })
}

fn process_message(store: &Store, message: &str, state: &mut State, now: i64) -> Value {
    if message == "歡迎" || message == "help" {
        return flex::greeting();
    }

    if message == "保存此分數" {
        let user_id = state.user_id.clone().unwrap_or_default();
        return match store.save_score(&user_id, state, now) {
            Ok(()) => {
                state.form = Form { params: Map::new(), waiting_for: Some(FIELDS[0].key.to_string()) };
                text_message("分數已成功保存")
            }
            Err(e) => {
                eprintln!("Store save_score error: {e}");
                text_message("保存分數時發生錯誤")
            }
        };
    }

    if message == "幫我算分數" || state.form.waiting_for.is_none() {
        return start(state);
    }

    // 修改某一欄
    if let Some(field) = fields::by_name(message) {
        state.form.params.remove(field.key);
        state.form.waiting_for = Some(field.key.to_string());
        return field.prompt();
    }

    if message == "修改房子" {
        state.form.params.remove("roomStyle");
        state.form.params.remove("room");
        state.form.waiting_for = Some("roomStyle".to_string());
        return fields::by_key("roomStyle").expect("roomStyle field").prompt();
    }

    // 回答目前的問題
    let current = state.form.waiting_for.as_deref().and_then(fields::by_key);
    let Some(current) = current else {
        // 狀態損毀（原版會丟例外）：從頭開始
        return start(state);
    };

    if current.validate(message) {
        state.form.params.insert(current.key.to_string(), Value::String(message.to_string()));

        if state.form.params.len() == FIELDS.len() {
            return calculator::calculate_result(&state.form.params);
        }
        return match FIELDS.iter().find(|f| !state.form.params.contains_key(f.key)) {
            Some(next) => {
                state.form.waiting_for = Some(next.key.to_string());
                next.prompt()
            }
            None => calculator::calculate_result(&state.form.params),
        };
    }

    // 答案無效，重問同一題
    current.prompt()
}

fn test_response() -> Value {
    let mut params = Map::new();
    for (k, v) in [
        ("field", "3"),
        ("pasture", "2"),
        ("grain", "1"),
        ("vegetable", "2"),
        ("sheep", "4"),
        ("wildBoar", "3"),
        ("cattle", "2"),
        ("emptyFarmyard", "1"),
        ("fencedStable", "1"),
        ("roomStyle", "石屋"),
        ("room", "5"),
        ("family", "3"),
        ("beggingCard", "1"),
        ("bonus", "2"),
        ("otherBonus", "1"),
    ] {
        params.insert(k.to_string(), Value::String(v.to_string()));
    }
    calculator::calculate_result(&params)
}

#[cfg(test)]
mod tests {
    use super::*;

    const NOW: i64 = 1_700_000_000;

    fn say(store: &Store, text: &str) -> Value {
        handle(store, "U1", text, NOW)
    }

    fn answers() -> Vec<&'static str> {
        // 與 test_response 相同的一組答案，總分 32
        vec!["3", "2", "1", "2", "4", "3", "2", "1", "1", "石屋", "5", "3", "1", "2", "1"]
    }

    fn play_all(store: &Store) -> Value {
        say(store, "幫我算分數");
        let mut last = Value::Null;
        for a in answers() {
            last = say(store, a);
        }
        last
    }

    #[test]
    fn first_message_starts_scoring() {
        let store = Store::open_in_memory().unwrap();
        let r = say(&store, "hello");
        assert_eq!(r["text"], "您耕了幾片田?");
        assert_eq!(r["quickReply"]["items"].as_array().unwrap().len(), 6);
    }

    #[test]
    fn greeting() {
        let store = Store::open_in_memory().unwrap();
        assert_eq!(say(&store, "歡迎")["type"], "flex");
        assert_eq!(say(&store, "help")["altText"], "歡迎來到農家樂分數計算機");
    }

    #[test]
    fn full_flow_gives_expected_total() {
        let store = Store::open_in_memory().unwrap();
        let r = play_all(&store);
        assert_eq!(r["type"], "flex");
        assert_eq!(calculator::total_of(&r), Some(32));
        assert_eq!(r, test_response());
    }

    #[test]
    fn invalid_answer_repeats_question() {
        let store = Store::open_in_memory().unwrap();
        say(&store, "幫我算分數");
        assert_eq!(say(&store, "abc")["text"], "您耕了幾片田?");
        assert_eq!(say(&store, "123")["text"], "您耕了幾片田?");
        assert_eq!(say(&store, "3")["text"], "您蓋出幾圈柵欄圈地?");
        // 柵欄圈地只接受一位數
        assert_eq!(say(&store, "10")["text"], "您蓋出幾圈柵欄圈地?");
    }

    #[test]
    fn modify_a_field_then_get_new_result() {
        let store = Store::open_in_memory().unwrap();
        play_all(&store);
        assert_eq!(say(&store, "田數")["text"], "您耕了幾片田?");
        let r = say(&store, "5"); // 田 5 片 = 4 分，原本 3 片 = 2 分
        assert_eq!(calculator::total_of(&r), Some(34));
    }

    #[test]
    fn modify_house_asks_style_then_room() {
        let store = Store::open_in_memory().unwrap();
        play_all(&store);
        assert!(say(&store, "修改房子")["text"].as_str().unwrap().contains("哪種房子"));
        assert!(say(&store, "磚屋")["text"].as_str().unwrap().contains("幾間房間"));
        let r = say(&store, "5"); // 石屋 10 分 -> 磚屋 5 分
        assert_eq!(calculator::total_of(&r), Some(27));
    }

    #[test]
    fn save_score_persists_and_resets() {
        let store = Store::open_in_memory().unwrap();
        play_all(&store);
        let before = store.count().unwrap();
        assert_eq!(say(&store, "保存此分數")["text"], "分數已成功保存");
        assert_eq!(store.count().unwrap(), before + 1);
        // 之後從頭開始
        assert_eq!(say(&store, "3")["text"], "您蓋出幾圈柵欄圈地?");
    }

    #[test]
    fn recommend_button_falls_through_like_original() {
        // 原版沒有處理「推薦給好友」，會被當成目前問題的答案而無效，重問最後一題
        let store = Store::open_in_memory().unwrap();
        play_all(&store);
        assert_eq!(say(&store, "推薦給好友")["text"], "您在職業卡和次要發展卡上的總得分是?");
    }

    #[test]
    fn test_command_does_not_touch_state() {
        let store = Store::open_in_memory().unwrap();
        say(&store, "幫我算分數");
        say(&store, "3");
        assert_eq!(say(&store, "test"), test_response());
        assert_eq!(say(&store, "2")["text"], "您有幾個小麥?(手上的以及田裡的)");
    }

    #[test]
    fn users_are_isolated() {
        let store = Store::open_in_memory().unwrap();
        handle(&store, "A", "幫我算分數", NOW);
        handle(&store, "A", "3", NOW);
        assert_eq!(handle(&store, "B", "幫我算分數", NOW)["text"], "您耕了幾片田?");
        assert_eq!(handle(&store, "A", "2", NOW)["text"], "您有幾個小麥?(手上的以及田裡的)");
    }

    #[test]
    fn expired_state_starts_over() {
        let store = Store::open_in_memory().unwrap();
        handle(&store, "A", "幫我算分數", NOW);
        handle(&store, "A", "3", NOW);
        let later = NOW + crate::store::TEMP_TTL_SECS + 1;
        assert_eq!(handle(&store, "A", "2", later)["text"], "您耕了幾片田?");
    }

    #[test]
    fn out_of_range_rooms_do_not_crash() {
        let mut p = Map::new();
        p.insert("roomStyle".into(), "磚屋".into());
        p.insert("room".into(), "20".into());
        assert_eq!(calculator::calculate_score("roomStyle", "磚屋", &p), 20);
    }
}
