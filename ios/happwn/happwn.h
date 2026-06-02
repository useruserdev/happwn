/* C declarations for the Rust crypto core. The implementation is linked from
 * HappwnCrypto.xcframework; this local copy guarantees the bridging header
 * resolves regardless of how Xcode propagates the xcframework's headers. */
#ifndef HAPPWN_H
#define HAPPWN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Decrypt a happ:// link. Returns a malloc'd JSON string; free with happwn_free. */
char *happwn_decrypt(const char *input);

/* Free a string returned by happwn_decrypt. */
void happwn_free(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* HAPPWN_H */
