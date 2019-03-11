#include <iostream>
#include <iomanip>
#include <fstream>

int main()
{
    std::ofstream ofs("divtable.mem");
    uint64_t w = 17;
    ofs << std::hex << std::setfill('0') << std::setw(6) << 0 << '\n';
    for (uint64_t i = 1; i < 1024; ++i) {
        uint64_t sh = 0;
        while (i > (1ull << sh)) sh++;
        uint64_t a = ((1ull << (sh + w)) + i - 1) / i;
        ofs << std::hex << std::setfill('0') << std::setw(6) << ((sh << 18) | a) << '\n';
    }
}
