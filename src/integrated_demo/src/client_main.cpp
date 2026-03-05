#include <chrono>
#include <fstream>
#include <iostream>
#include <thread>

#include <httplib.h>
#include <nlohmann/json.hpp>

static nlohmann::json LoadJsonFile(const std::string& path)
{
    std::ifstream ifs(path);
    if (!ifs) {
        return nlohmann::json::object();
    }
    nlohmann::json j;
    try {
        ifs >> j;
    }
    catch (...) {
        return nlohmann::json::object();
    }
    return j;
}

int main(int argc, char** argv)
{
    try {
        std::string base_url = "http://127.0.0.1:18080";
        std::string request_path = "config/request.json";

        if (argc >= 2) {
            base_url = argv[1]; // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic)
        }
        if (argc >= 3) {
            request_path = argv[2]; // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic)
        }

        httplib::Client cli(base_url);
        cli.set_connection_timeout(2);
        cli.set_read_timeout(2);

        if (auto res = cli.Get("/health")) {
            std::cout << "GET /health => " << res->status << "\n"
                      << res->body << "\n";
        } else {
            std::cerr << "GET /health failed\n";
        }

        if (auto res = cli.Get("/time")) {
            std::cout << "GET /time => " << res->status << "\n"
                      << res->body << "\n";
        } else {
            std::cerr << "GET /time failed\n";
        }

        const nlohmann::json req = LoadJsonFile(request_path);
        if (auto res =
                cli.Post("/echo", req.dump(), "application/json")) {
            std::cout << "POST /echo => " << res->status << "\n"
                      << res->body << "\n";
        } else {
            std::cerr << "POST /echo failed\n";
        }

        if (auto res = cli.Get("/config")) {
            std::cout << "GET /config => " << res->status << "\n"
                      << res->body << "\n";
        } else {
            std::cerr << "GET /config failed\n";
        }

        return 0;
    }
    catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << "\n";
        return 1;
    }
    catch (...) {
        std::cerr << "Unknown exception\n";
        return 1;
    }
}
