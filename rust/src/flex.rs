//! LINE Flex 訊息（對應 aws/lambda/flex.rb）。

use serde_json::{json, Map, Value};

use crate::fields;

const GREEN: &str = "#1DB446";
const RED: &str = "#DD0000";

fn color(score: i64) -> &'static str {
    if score >= 0 {
        GREEN
    } else {
        RED
    }
}

fn row(label: String, score: i64, modify_text: &str) -> Value {
    json!({
        "type": "box",
        "layout": "horizontal",
        "margin": "lg",
        "contents": [
            { "type": "text", "text": label, "size": "sm", "flex": 1 },
            { "type": "text", "text": score.to_string(), "size": "sm", "color": color(score), "align": "end", "flex": 0 },
            { "type": "text", "text": "修改", "action": { "type": "message", "text": modify_text }, "color": "#225588", "margin": "md", "flex": 0 }
        ]
    })
}

fn param<'a>(params: &'a Map<String, Value>, key: &str) -> &'a str {
    params.get(key).and_then(Value::as_str).unwrap_or("")
}

pub fn generate(scores: &[(&str, i64)], total: i64, params: &Map<String, Value>) -> Value {
    let mut items: Vec<Value> = Vec::new();
    for key in crate::calculator::DISPLAY_ORDER {
        let Some((_, score)) = scores.iter().find(|(k, _)| *k == key) else {
            continue;
        };
        if key == "roomStyle" {
            items.push(row(
                format!("房子: {} {}間", param(params, "roomStyle"), param(params, "room")),
                *score,
                "修改房子",
            ));
        } else if key == "room" {
            continue;
        } else if let Some(field) = fields::by_key(key) {
            items.push(row(format!("{}: {}", field.name, param(params, key)), *score, field.name));
        }
    }

    json!({
        "type": "flex",
        "altText": format!("分數計算結果：總分 {}", total),
        "contents": {
            "type": "bubble",
            "header": {
                "type": "box",
                "layout": "vertical",
                "contents": [
                    { "type": "text", "text": "分數計算結果", "weight": "bold", "color": GREEN, "size": "xl", "align": "center" }
                ],
                "backgroundColor": "#f6f6f6",
                "paddingTop": "lg",
                "paddingBottom": "lg"
            },
            "body": {
                "type": "box",
                "layout": "vertical",
                "contents": [
                    { "type": "box", "layout": "vertical", "spacing": "none", "contents": items, "margin": "none" },
                    { "type": "separator", "margin": "xxl", "color": "#cccccc" },
                    {
                        "type": "box",
                        "layout": "horizontal",
                        "margin": "xl",
                        "contents": [
                            { "type": "text", "text": "總分", "size": "xl", "weight": "bold", "color": "#555555" },
                            { "type": "text", "text": total.to_string(), "size": "xl", "weight": "bold", "color": color(total), "align": "end", "margin": "sm" }
                        ]
                    }
                ]
            },
            "footer": {
                "type": "box",
                "layout": "vertical",
                "spacing": "sm",
                "contents": [
                    { "type": "button", "style": "primary", "color": GREEN, "action": { "type": "message", "label": "再算一次", "text": "幫我算分數" } },
                    { "type": "button", "style": "primary", "color": "#2C7BB6", "action": { "type": "message", "label": "保存此分數", "text": "保存此分數" } },
                    { "type": "button", "style": "secondary", "action": { "type": "message", "label": "推薦給好友", "text": "推薦給好友" } }
                ],
                "paddingAll": "lg"
            },
            "styles": { "header": { "separator": false }, "footer": { "separator": true } }
        }
    })
}

pub fn greeting() -> Value {
    json!({
        "type": "flex",
        "altText": "歡迎來到農家樂分數計算機",
        "contents": {
            "type": "bubble",
            "body": {
                "type": "box",
                "layout": "vertical",
                "contents": [
                    { "type": "text", "text": "歡迎來到農家樂分數計算機，請點擊按鈕開始算分數：", "wrap": true },
                    {
                        "type": "button",
                        "action": { "type": "message", "label": "開始計算", "text": "幫我算分數" },
                        "style": "primary",
                        "color": "#225588",
                        "margin": "md"
                    }
                ]
            }
        }
    })
}
