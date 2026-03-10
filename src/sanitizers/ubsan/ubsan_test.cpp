#include <iostream>
#include <limits>

/**
 * @brief Demonstrates signed integer overflow, which is undefined behavior in C++.
 */
void IntegerOverflow()
{
    std::cout << "--- Running Integer Overflow ---" << std::endl;
    int max_int = std::numeric_limits<int>::max();
    // Signed integer overflow is UB
    int overflow = max_int + 1; 
    std::cout << "Overflow result: " << overflow << std::endl;
}

/**
 * @brief Demonstrates a shift operation that exceeds the width of the type.
 */
void ShiftOverflow()
{
    std::cout << "--- Running Shift Overflow ---" << std::endl;
    int val = 1;
    // Shift count is equal to or greater than the width of the promoted type
    int result = val << 32; 
    std::cout << "Shift result: " << result << std::endl;
}

/**
 * @brief Demonstrates null pointer dereference, which is UB.
 */
void NullPointerDereference()
{
    std::cout << "--- Running Null Pointer Dereference ---" << std::endl;
    int* ptr = nullptr;
    // Dereferencing a null pointer is UB
    std::cout << "Value at null pointer: " << *ptr << std::endl;
}

int main(int argc, char** argv)
{
    IntegerOverflow();
    ShiftOverflow();
    if (argc > 1 && std::string(argv[1]) == "null")
    {
        NullPointerDereference();
    }
    return 0;
}
