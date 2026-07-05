#ifndef OCWS_KV_H
#define OCWS_KV_H

typedef struct ocws_kv ocws_kv;

/* Open/create a KV store from a file path.
 * Creates the file and parent dirs if they don't exist.
 * Returns NULL on failure. */
ocws_kv *ocws_kv_open(const char *path);

/* Close and free all resources. Flushes pending writes. */
void ocws_kv_close(ocws_kv *kv);

/* Get a value by key. Returns NULL if not found.
 * Caller must free() the returned string. */
char *ocws_kv_get(ocws_kv *kv, const char *key);

/* Get a value by key, returning def if not found.
 * Caller must free() the returned string. */
char *ocws_kv_get_or(ocws_kv *kv, const char *key, const char *def);

/* Set a key-value pair. Overwrites if key exists.
 * Returns 0 on success, -1 on failure. */
int ocws_kv_set(ocws_kv *kv, const char *key, const char *value);

/* Delete a key. Returns 0 if deleted, -1 if not found or error. */
int ocws_kv_del(ocws_kv *kv, const char *key);

/* Check if a key exists. Returns 1 if found, 0 otherwise. */
int ocws_kv_has(ocws_kv *kv, const char *key);

/* List keys with an optional prefix filter (NULL = all).
 * Calls callback for each matching entry with user context.
 * Returns number of entries listed. */
typedef void (*ocws_kv_list_fn)(const char *key, const char *value, void *ctx);
int ocws_kv_list(ocws_kv *kv, const char *prefix, ocws_kv_list_fn callback, void *ctx);

/* Flush pending writes to disk. Called automatically on close. */
int ocws_kv_flush(ocws_kv *kv);

#endif /* OCWS_KV_H */
