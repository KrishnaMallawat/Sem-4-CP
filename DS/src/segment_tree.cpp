#include "segment_tree.h"
#include <algorithm>
SegmentTree::SegmentTree(size_t genome_length) : n_(genome_length) {
    tree_.resize(4 * n_ + 4);
    if (n_ > 0) build(1, 0, n_ - 1);
}
void SegmentTree::build(size_t node, size_t start, size_t end) {
    tree_[node].range_min = start;
    tree_[node].range_max = end;
    if (start == end) return;
    size_t mid = start + (end - start) / 2;
    build(2 * node,     start,   mid);
    build(2 * node + 1, mid + 1, end);
}
bool SegmentTree::overlaps(size_t node, size_t lo, size_t hi) const {
    return !(tree_[node].range_max < lo || tree_[node].range_min > hi);
}
std::vector<size_t> SegmentTree::query_range(const std::vector<size_t>& candidates,size_t lo, size_t hi) const {
    std::vector<size_t> result;
    if (candidates.empty() || lo > hi || n_ == 0) return result;
    size_t clamped_lo = lo;
    size_t clamped_hi = std::min(hi, n_ - 1);
    for (size_t pos : candidates) {
        if (pos >= clamped_lo && pos <= clamped_hi) {
            size_t node  = 1;
            size_t start = 0;
            size_t end   = n_ - 1;
            bool accepted = false;
            while (start <= end) {
                if (!overlaps(node, clamped_lo, clamped_hi)) break;
                if (start == end) { accepted = true; break; }
                size_t mid = start + (end - start) / 2;
                if (pos <= mid) {
                    node  = 2 * node;
                    end   = mid;
                } else {
                    node  = 2 * node + 1;
                    start = mid + 1;
                }
            }
            if (accepted) result.push_back(pos);
        }
    }
    return result;
}