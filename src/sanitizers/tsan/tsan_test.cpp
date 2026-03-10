#include <iostream>
#include <thread>
#include <vector>
#include <mutex>
#include <chrono>

int shared_counter = 0;

/**
 * @brief Demonstrates a data race that TSan can detect.
 */
void DataRace()
{
    std::cout << "--- Running Data Race ---" << std::endl;
    std::thread t1([]() {
        for (int i = 0; i < 10000; ++i) {
            // Unsynchronized access to a shared variable
            shared_counter++;
        }
    });
    std::thread t2([]() {
        for (int i = 0; i < 10000; ++i) {
            // Unsynchronized access to a shared variable
            shared_counter++;
        }
    });
    t1.join();
    t2.join();
    std::cout << "Final counter value: " << shared_counter << std::endl;
}

std::mutex m1, m2;

/**
 * @brief Demonstrates a potential deadlock that TSan can detect (in some cases).
 */
void Deadlock()
{
    std::cout << "--- Running Deadlock Simulation ---" << std::endl;
    std::thread t1([]() {
        std::lock_guard<std::mutex> l1(m1);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> l2(m2);
    });
    std::thread t2([]() {
        std::lock_guard<std::mutex> l2(m2);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> l1(m1);
    });
    t1.join();
    t2.join();
}

int main(int argc, char** argv)
{
    if (argc > 1 && std::string(argv[1]) == "deadlock")
    {
        Deadlock();
    }
    else
    {
        DataRace();
    }
    return 0;
}
