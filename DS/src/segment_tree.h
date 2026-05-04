#pragma once
#include <vector>
#include <cstddef>
struct SegmentNode {
    size_t range_min;
    size_t range_max;
};
class SegmentTree {
public:
    explicit SegmentTree(size_t genome_length);
    std::vector<size_t> query_range(const std::vector<size_t>& candidates,size_t lo, size_t hi) const;
    size_t genome_length() const { return n_; }
private:
    size_t n_;
    std::vector<SegmentNode> tree_;
    void build(size_t node, size_t start, size_t end);
    bool overlaps(size_t node, size_t lo, size_t hi) const;
};