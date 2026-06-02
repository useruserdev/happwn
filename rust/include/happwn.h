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
