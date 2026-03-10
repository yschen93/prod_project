#include <iostream>
#include <vector>
#include <cstdlib>

/**
 * @brief Demonstrates a heap buffer overflow that ASan can detect.
 */
void HeapBufferOverflow(int index)
{
    std::cout << "--- Running Heap Buffer Overflow at index " << index << " ---" << std::endl;
    volatile int* array = new int[10];
    // Use the index to prevent compile-time optimization
    array[index] = 42; 
    std::cout << "Value at array[" << index << "]: " << array[index] << std::endl;
    delete[] array;
}

/**
 * @brief Demonstrates a memory leak that LeakSanitizer (part of ASan) can detect.
 */
void MemoryLeak()
{
    std::cout << "--- Running Memory Leak ---" << std::endl;
    // Allocate to a local pointer and don't free it.
    // LSan will see this as leaked because it's no longer reachable after the function returns.
    void* p = malloc(100);
    // Use the pointer to ensure the compiler doesn't optimize it away.
    if (p) {
        static_cast<char*>(p)[0] = 'a';
    }
}

int main(int argc, char** argv)
{
    int index = 1; // Default to a safe index
    if (argc > 1) index = std::atoi(argv[1]);
    
    // If index is within bounds, run the test and continue
    // If index is out of bounds (e.g., 10), ASan will abort here
    HeapBufferOverflow(index);
    
    // Run memory leak test
    MemoryLeak();
    
    return 0;
}
