//! 計分邏輯（對應 aws/lambda/calculator.rb）。

use serde_json::{Map, Value};

use crate::flex;

pub const DISPLAY_ORDER: [&str; 14] = [
    "field",
    "pasture",
    "grain",
    "vegetable",
    "sheep",
    "wildBoar",
    "cattle",
    "emptyFarmyard",
    "fencedStable",
    "roomStyle",
    "family",
    "beggingCard",
    "bonus",
    "otherBonus",
];

fn table(key: &str) -> Option<&'static [i64]> {
    Some(match key {
        "field" => &[-1, -1, 1, 2, 3, 4, 4, 4, 4, 4],
        "pasture" => &[-1, 1, 2, 3, 4, 4, 4, 4, 4],
        "grain" => &[-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
        "vegetable" => &[-1, 1, 2, 3, 4, 4, 4, 4, 4],
        "sheep" => &[-1, 1, 1, 1, 2, 2, 3, 3, 4, 4],
        "wildBoar" => &[-1, 1, 1, 2, 2, 3, 3, 4, 4],
        "cattle" => &[-1, 1, 2, 2, 3, 3, 4, 4, 4],
        _ => return None,
    })
}

/// Ruby 的 String#to_i：取開頭的數字，沒有就是 0。
fn to_i(s: &str) -> i64 {
    let digits: String = s.trim().chars().take_while(|c| c.is_ascii_digit()).collect();
    digits.parse().unwrap_or(0)
}

fn param<'a>(params: &'a Map<String, Value>, key: &str) -> &'a str {
    params.get(key).and_then(Value::as_str).unwrap_or("")
}

pub fn calculate_score(key: &str, value: &str, params: &Map<String, Value>) -> i64 {
    match key {
        "field" | "pasture" | "grain" | "vegetable" | "sheep" | "wildBoar" | "cattle" => {
            let t = table(key).expect("known key");
            let idx = to_i(value) as usize;
            if idx < t.len() {
                t[idx]
            } else {
                *t.last().expect("non-empty table")
            }
        }
        "emptyFarmyard" => to_i(value) * -1,
        "fencedStable" => to_i(value),
        "roomStyle" => {
            let rooms = to_i(param(params, "room"));
            match value {
                "木屋" => 0,
                "磚屋" => rooms,
                "石屋" => rooms * 2,
                // 原版會在這裡因 nil 而丟例外（房型驗證沒加 ^$）；這裡改為不計分。
                _ => 0,
            }
        }
        "room" => 0,
        "family" => to_i(value) * 3,
        "beggingCard" => to_i(value) * -3,
        "bonus" | "otherBonus" => to_i(value),
        _ => 0,
    }
}

/// 回傳 LINE Flex 訊息
pub fn calculate_result(params: &Map<String, Value>) -> Value {
    let mut scores: Vec<(&'static str, i64)> = Vec::new();
    let mut total = 0;
    for key in DISPLAY_ORDER {
        let Some(v) = params.get(key).and_then(Value::as_str) else {
            continue;
        };
        let s = calculate_score(key, v, params);
        scores.push((key, s));
        total += s;
    }
    flex::generate(&scores, total, params)
}

#[cfg(test)]
pub fn total_of(flex: &Value) -> Option<i64> {
    // 方便測試：altText 格式為「分數計算結果：總分 N」
    flex.get("altText")?
        .as_str()?
        .rsplit(' ')
        .next()?
        .parse()
        .ok()
}
