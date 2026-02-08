#ifndef PACT_RUNTIME_H
#define PACT_RUNTIME_H

#if !defined(_POSIX_C_SOURCE) && !defined(_GNU_SOURCE) && !defined(__APPLE__)
#define _POSIX_C_SOURCE 200809L
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

static const char* pact_int_to_str(int64_t n) {
    char buf[32];
    snprintf(buf, sizeof(buf), "%lld", (long long)n);
    return strdup(buf);
}

static void* pact_alloc(int64_t size) {
    void* p = malloc((size_t)size);
    if (!p) {
        fprintf(stderr, "pact: out of memory\n");
        exit(1);
    }
    return p;
}

typedef struct {
    void** items;
    int64_t len;
    int64_t cap;
} pact_list;

static pact_list* pact_list_new(void) {
    pact_list* l = (pact_list*)pact_alloc(sizeof(pact_list));
    l->cap = 8;
    l->len = 0;
    l->items = (void**)pact_alloc(sizeof(void*) * l->cap);
    return l;
}

static void pact_list_push(pact_list* l, void* item) {
    if (l->len >= l->cap) {
        l->cap *= 2;
        l->items = (void**)realloc(l->items, sizeof(void*) * (size_t)l->cap);
        if (!l->items) {
            fprintf(stderr, "pact: out of memory\n");
            exit(1);
        }
    }
    l->items[l->len++] = item;
}

static void* pact_list_get(pact_list* l, int64_t index) {
    if (index < 0 || index >= l->len) {
        fprintf(stderr, "pact: list index out of bounds: %lld\n", (long long)index);
        exit(1);
    }
    return l->items[index];
}

static int64_t pact_list_len(pact_list* l) {
    return l->len;
}

static void pact_list_set(pact_list* l, int64_t index, void* item) {
    if (index < 0 || index >= l->len) {
        fprintf(stderr, "pact: list set index out of bounds: %lld\n", (long long)index);
        exit(1);
    }
    l->items[index] = item;
}

static void* pact_list_pop(pact_list* l) {
    if (l->len <= 0) {
        fprintf(stderr, "pact: list pop on empty list\n");
        exit(1);
    }
    l->len--;
    return l->items[l->len];
}

static void pact_list_free(pact_list* l) {
    if (l) {
        free(l->items);
        free(l);
    }
}

static int64_t pact_str_len(const char* s) {
    return (int64_t)strlen(s);
}

static int64_t pact_str_char_at(const char* s, int64_t i) {
    return (int64_t)(unsigned char)s[i];
}

static const char* pact_str_substr(const char* s, int64_t start, int64_t len) {
    char* buf = (char*)pact_alloc(len + 1);
    memcpy(buf, s + start, (size_t)len);
    buf[len] = '\0';
    return buf;
}

static const char* pact_str_concat(const char* a, const char* b) {
    int64_t la = pact_str_len(a);
    int64_t lb = pact_str_len(b);
    char* buf = (char*)pact_alloc(la + lb + 1);
    memcpy(buf, a, (size_t)la);
    memcpy(buf + la, b, (size_t)lb);
    buf[la + lb] = '\0';
    return buf;
}

static int pact_str_eq(const char* a, const char* b) {
    return strcmp(a, b) == 0;
}

static int pact_str_contains(const char* s, const char* needle) {
    return strstr(s, needle) != NULL;
}

static int pact_str_starts_with(const char* s, const char* prefix) {
    size_t plen = strlen(prefix);
    return strncmp(s, prefix, plen) == 0;
}

static const char* pact_read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        fprintf(stderr, "pact: cannot open file: %s\n", path);
        exit(1);
    }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* buf = (char*)pact_alloc(size + 1);
    fread(buf, 1, (size_t)size, f);
    buf[size] = '\0';
    fclose(f);
    return buf;
}

static void pact_write_file(const char* path, const char* content) {
    FILE* f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "pact: cannot open file for writing: %s\n", path);
        exit(1);
    }
    size_t len = strlen(content);
    fwrite(content, 1, len, f);
    fclose(f);
}

static int pact_g_argc = 0;
static const char** pact_g_argv = NULL;

static int64_t pact_arg_count(void) {
    return (int64_t)pact_g_argc;
}

static const char* pact_get_arg(int64_t index) {
    if (index < 0 || index >= pact_g_argc) {
        fprintf(stderr, "pact: arg index out of bounds: %lld\n", (long long)index);
        exit(1);
    }
    return pact_g_argv[index];
}

#endif
