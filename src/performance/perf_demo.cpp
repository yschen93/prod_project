#include <iostream>
#include <vector>
#include <algorithm>
#include <chrono>
#include <random>

/**
 * @brief Demonstrates row-major vs column-major access (Cache Misses).
 */
void CachePerformanceTest(size_t size)
{
    std::cout << "--- Cache Performance Test (Size: " << size << "x" << size << ") ---" << std::endl;
    std::vector<int> matrix(size * size, 1);

    // Row-major access (Fast)
    auto start_row = std::chrono::high_resolution_clock::now();
    long long sum_row = 0;
    for (size_t i = 0; i < size; ++i)
        for (size_t j = 0; j < size; ++j)
            sum_row += matrix[i * size + j];
    auto end_row = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> row_time = end_row - start_row;
    std::cout << "Row-major sum: " << sum_row << " (Time: " << row_time.count() << " ms)" << std::endl;

    // Column-major access (Slow due to cache misses)
    auto start_col = std::chrono::high_resolution_clock::now();
    long long sum_col = 0;
    for (size_t j = 0; j < size; ++j)
        for (size_t i = 0; i < size; ++i)
            sum_col += matrix[i * size + j];
    auto end_col = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> col_time = end_col - start_col;
    std::cout << "Column-major sum: " << sum_col << " (Time: " << col_time.count() << " ms)" << std::endl;
}

/**
 * @brief Demonstrates sorted vs unsorted processing (Branch Mispredictions).
 */
void BranchPerformanceTest(size_t size)
{
    std::cout << "--- Branch Performance Test (Size: " << size << ") ---" << std::endl;
    std::vector<int> data(size);
    std::mt19937 gen(42);
    std::uniform_int_distribution<> dis(0, 255);
    for (auto& x : data) x = dis(gen);

    auto process_data = [&](const std::vector<int>& v, const char* label) {
        auto start = std::chrono::high_resolution_clock::now();
        long long sum = 0;
        for (size_t i = 0; i < 100; ++i) { // Repeat to amplify time
            for (auto x : v) {
                if (x >= 128) sum += x;
            }
        }
        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> time = end - start;
        std::cout << label << " sum: " << sum << " (Time: " << time.count() << " ms)" << std::endl;
    };

    process_data(data, "Unsorted data");
    std::sort(data.begin(), data.end());
    process_data(data, "Sorted data  ");
}

/**
 * @brief CPU Hotspot (Computationally expensive function).
 */
void CPUHotspotTest(int iterations)
{
    std::cout << "--- CPU Hotspot Test (" << iterations << " iterations) ---" << std::endl;
    double result = 0.0;
    for (int i = 0; i < iterations; ++i) {
        result += std::sin(i) * std::cos(i);
    }
    std::cout << "Hotspot result: " << result << std::endl;
}

int main(int argc, char** argv)
{
    CachePerformanceTest(2000);
    BranchPerformanceTest(100000);
    CPUHotspotTest(50000000);
    return 0;
}
