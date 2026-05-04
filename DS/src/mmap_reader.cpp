#include "mmap_reader.h"
#include <cstdlib>
#include <cstdio>

// ── Windows ────────────────────────────────────────────────────────────────
#if defined(_WIN32) || defined(PLATFORM_WINDOWS)
#include <windows.h>

struct WinImpl { HANDLE file; HANDLE mapping; };

MmapHandle* mmap_open(const std::string& filepath) {
    auto* impl = new WinImpl();
    impl->file = CreateFileA(filepath.c_str(), GENERIC_READ, FILE_SHARE_READ,
                             nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (impl->file == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "mmap_open: cannot open '%s'\n", filepath.c_str());
        delete impl; return nullptr;
    }
    LARGE_INTEGER fs;
    if (!GetFileSizeEx(impl->file, &fs)) {
        CloseHandle(impl->file); delete impl; return nullptr;
    }
    impl->mapping = CreateFileMappingA(impl->file, nullptr, PAGE_READONLY, 0, 0, nullptr);
    if (!impl->mapping) {
        CloseHandle(impl->file); delete impl; return nullptr;
    }
    void* data = MapViewOfFile(impl->mapping, FILE_MAP_READ, 0, 0, 0);
    if (!data) {
        CloseHandle(impl->mapping); CloseHandle(impl->file); delete impl; return nullptr;
    }
    auto* h = new MmapHandle();
    h->data = static_cast<const char*>(data);
    h->size = static_cast<size_t>(fs.QuadPart);
    h->_impl = impl;
    return h;
}

void mmap_close(MmapHandle* h) {
    if (!h) return;
    auto* impl = static_cast<WinImpl*>(h->_impl);
    UnmapViewOfFile(const_cast<char*>(h->data));
    CloseHandle(impl->mapping);
    CloseHandle(impl->file);
    delete impl; delete h;
}

// ── Unix / macOS ───────────────────────────────────────────────────────────
#else
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

struct UnixImpl { int fd; };

MmapHandle* mmap_open(const std::string& filepath) {
    auto* impl = new UnixImpl();
    impl->fd = open(filepath.c_str(), O_RDONLY);
    if (impl->fd < 0) {
        fprintf(stderr, "mmap_open: cannot open '%s'\n", filepath.c_str());
        delete impl; return nullptr;
    }
    struct stat st;
    if (fstat(impl->fd, &st) < 0) { close(impl->fd); delete impl; return nullptr; }

    void* data = mmap(nullptr, static_cast<size_t>(st.st_size),
                      PROT_READ, MAP_PRIVATE, impl->fd, 0);
    if (data == MAP_FAILED) { close(impl->fd); delete impl; return nullptr; }

    auto* h = new MmapHandle();
    h->data = static_cast<const char*>(data);
    h->size = static_cast<size_t>(st.st_size);
    h->_impl = impl;
    return h;
}

void mmap_close(MmapHandle* h) {
    if (!h) return;
    auto* impl = static_cast<UnixImpl*>(h->_impl);
    munmap(const_cast<char*>(h->data), h->size);
    close(impl->fd);
    delete impl; delete h;
}
#endif
