//! LINE Messaging API：webhook 簽章驗證與 reply。

use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use hmac::{Hmac, Mac};
use serde_json::{json, Value};
use sha2::Sha256;

/// 驗證 X-Line-Signature：base64(HMAC-SHA256(channel_secret, body))
pub fn verify_signature(channel_secret: &str, body: &[u8], signature_b64: &str) -> bool {
    let Ok(sig) = STANDARD.decode(signature_b64.trim()) else {
        return false;
    };
    let Ok(mut mac) = Hmac::<Sha256>::new_from_slice(channel_secret.as_bytes()) else {
        return false;
    };
    mac.update(body);
    mac.verify_slice(&sig).is_ok() // 常數時間比較
}

#[cfg(test)]
pub fn sign(channel_secret: &str, body: &[u8]) -> String {
    let mut mac = Hmac::<Sha256>::new_from_slice(channel_secret.as_bytes()).expect("hmac key");
    mac.update(body);
    STANDARD.encode(mac.finalize().into_bytes())
}

/// 呼叫 reply API（阻塞式，請在 spawn_blocking 內使用）
pub fn reply(api_base: &str, access_token: &str, reply_token: &str, message: &Value) -> Result<(), String> {
    let url = format!("{}/v2/bot/message/reply", api_base.trim_end_matches('/'));
    let body = json!({ "replyToken": reply_token, "messages": [message] });
    match ureq::post(&url)
        .set("Authorization", &format!("Bearer {access_token}"))
        .timeout(std::time::Duration::from_secs(10))
        .send_json(body)
    {
        Ok(_) => Ok(()),
        Err(ureq::Error::Status(code, resp)) => {
            let detail = resp.into_string().unwrap_or_default();
            Err(format!("LINE API Error: {code} {detail}"))
        }
        Err(e) => Err(format!("LINE API request failed: {e}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signature_roundtrip() {
        let body = br#"{"events":[]}"#;
        let sig = sign("secret", body);
        assert!(verify_signature("secret", body, &sig));
        assert!(!verify_signature("other", body, &sig));
        assert!(!verify_signature("secret", b"tampered", &sig));
        assert!(!verify_signature("secret", body, ""));
        assert!(!verify_signature("secret", body, "!!!not base64"));
    }

    #[test]
    fn matches_known_hmac_vector() {
        // HMAC-SHA256(key="key", msg="The quick brown fox jumps over the lazy dog")
        // = f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8
        let expected = STANDARD.encode(
            (0..32)
                .map(|i| u8::from_str_radix(&"f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"[i * 2..i * 2 + 2], 16).unwrap())
                .collect::<Vec<u8>>(),
        );
        assert_eq!(sign("key", b"The quick brown fox jumps over the lazy dog"), expected);
    }
}
