//! C ABI for the iOS Swift bridge. Returns a JSON envelope string the caller must
//! free with `happwn_free`.
//!
//! Success: {"ok":true,"mode":"crypt4","value":"https://..."}
//! Failure: {"ok":false,"error":"..."}

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Decrypt `input` (a NUL-terminated happ:// link). Returns a newly-allocated
/// NUL-terminated JSON string. Caller MUST pass it to `happwn_free`.
///
/// # Safety
/// `input` must be a valid NUL-terminated C string or null.
#[no_mangle]
pub unsafe extern "C" fn happwn_decrypt(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return envelope_error("null input");
    }
    let link = CStr::from_ptr(input).to_string_lossy().into_owned();

    let json = match crate::decrypt(&link) {
        Ok(d) => serde_json::json!({ "ok": true, "mode": d.mode, "value": d.value }),
        Err(e) => serde_json::json!({ "ok": false, "error": e }),
    };
    to_c_string(json.to_string())
}

/// Free a string previously returned by `happwn_decrypt`.
///
/// # Safety
/// `ptr` must be a pointer returned by `happwn_decrypt`, or null.
#[no_mangle]
pub unsafe extern "C" fn happwn_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}

fn envelope_error(msg: &str) -> *mut c_char {
    to_c_string(serde_json::json!({ "ok": false, "error": msg }).to_string())
}

fn to_c_string(s: String) -> *mut c_char {
    // Replace interior NULs defensively; JSON of our data never contains them.
    CString::new(s.replace('\0', "")).unwrap().into_raw()
}
