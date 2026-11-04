//! 計分欄位定義（對應 aws/lambda/fields.rb）。

use serde_json::{json, Value};

pub struct Field {
    pub key: &'static str,
    pub name: &'static str,
    pub question: &'static str,
    pub options: &'static [&'static str],
    validator: fn(&str) -> bool,
}

impl Field {
    pub fn validate(&self, input: &str) -> bool {
        (self.validator)(input)
    }

    /// LINE 文字訊息 + quick reply 按鈕
    pub fn prompt(&self) -> Value {
        let items: Vec<Value> = self
            .options
            .iter()
            .map(|o| {
                json!({
                    "type": "action",
                    "action": { "type": "message", "label": o, "text": o }
                })
            })
            .collect();
        json!({
            "type": "text",
            "text": self.question,
            "quickReply": { "items": items }
        })
    }
}

fn digits(s: &str, min: usize, max: usize) -> bool {
    let n = s.len();
    n >= min && n <= max && s.bytes().all(|b| b.is_ascii_digit())
}
fn one_or_two_digits(s: &str) -> bool {
    digits(s, 1, 2)
}
fn one_digit(s: &str) -> bool {
    digits(s, 1, 1)
}
fn zero_to_four(s: &str) -> bool {
    matches!(s, "0" | "1" | "2" | "3" | "4")
}
fn two_to_five(s: &str) -> bool {
    matches!(s, "2" | "3" | "4" | "5")
}
/// 原版 regex 為 `(木|磚|石)屋`，沒有加 ^$，所以「包含」即通過。
fn house_style(s: &str) -> bool {
    s.contains("木屋") || s.contains("磚屋") || s.contains("石屋")
}

const NUM_0_TO_12: &[&str] = &["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"];
const NUM_2_TO_14: &[&str] = &["2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"];

pub static FIELDS: [Field; 15] = [
    Field { key: "field", name: "田數", question: "您耕了幾片田?", options: &["0", "1", "2", "3", "4", "5"], validator: one_or_two_digits },
    Field { key: "pasture", name: "柵欄圈地數", question: "您蓋出幾圈柵欄圈地?", options: &["0", "1", "2", "3", "4", "5"], validator: one_digit },
    Field { key: "grain", name: "小麥數", question: "您有幾個小麥?(手上的以及田裡的)", options: &["0", "1", "2", "3", "4", "5", "6", "7", "8"], validator: one_or_two_digits },
    Field { key: "vegetable", name: "蔬菜數", question: "您有幾個蔬菜?(手上的以及田裡的)", options: &["0", "1", "2", "3", "4"], validator: one_or_two_digits },
    Field { key: "sheep", name: "羊數", question: "您養了幾頭羊?", options: &["0", "1", "2", "3", "4", "5", "6", "7", "8"], validator: one_or_two_digits },
    Field { key: "wildBoar", name: "豬數", question: "您養了幾頭豬?", options: &["0", "1", "2", "3", "4", "5", "6", "7"], validator: one_or_two_digits },
    Field { key: "cattle", name: "牛數", question: "您養了幾頭牛?", options: &["0", "1", "2", "3", "4", "5", "6"], validator: one_or_two_digits },
    Field { key: "emptyFarmyard", name: "空地數", question: "您有幾片未使用的空地?", options: NUM_0_TO_12, validator: one_or_two_digits },
    Field { key: "fencedStable", name: "柵欄圈地內馬廄數", question: "您蓋了幾間在柵欄圈地內的馬廄?", options: &["0", "1", "2", "3", "4"], validator: zero_to_four },
    Field { key: "roomStyle", name: "房間類型", question: "您住在哪種房子? (木屋, 磚屋, 石屋)", options: &["木屋", "磚屋", "石屋"], validator: house_style },
    Field { key: "room", name: "房間數", question: "您家有幾間房間? (包含一開始的兩間)", options: NUM_2_TO_14, validator: one_or_two_digits },
    Field { key: "family", name: "人口數", question: "您家有幾個人?", options: &["2", "3", "4", "5"], validator: two_to_five },
    Field { key: "beggingCard", name: "乞討卡", question: "您拿到幾張乞討卡?", options: NUM_0_TO_12, validator: one_or_two_digits },
    Field { key: "bonus", name: "主要發展卡的的總得分", question: "您在主要發展卡上的總得分是?", options: NUM_0_TO_12, validator: one_or_two_digits },
    Field { key: "otherBonus", name: "職業卡和次要發展卡的總得分", question: "您在職業卡和次要發展卡上的總得分是?", options: NUM_0_TO_12, validator: one_or_two_digits },
];

pub fn by_key(key: &str) -> Option<&'static Field> {
    FIELDS.iter().find(|f| f.key == key)
}

pub fn by_name(name: &str) -> Option<&'static Field> {
    FIELDS.iter().find(|f| f.name == name)
}
