#include <cstdlib>
#include <fstream>
#include <iostream>

#include <httplib.h>
#include <nlohmann/json.hpp>

#include "integrated_demo/AppConfig.h"
#include "integrated_demo/Logging.h"
#include "integrated_demo/RestServer.h"

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
        std::string yaml_path = "config/server.yaml";
        std::string json_override_path;

        if (argc >= 2) {
            yaml_path = argv[1]; // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic)
        }
        if (argc >= 3) {
            json_override_path = argv[2]; // NOLINT(cppcoreguidelines-pro-bounds-pointer-arithmetic)
        }

        auto cfg_opt =
            integrated_demo::LoadConfigFromYamlFile(yaml_path);
        if (!cfg_opt) {
            std::cerr << "failed to load yaml config: " << yaml_path
                      << "\n";
            return 2;
        }

        integrated_demo::AppConfig cfg = *cfg_opt;
        if (!json_override_path.empty()) {
            integrated_demo::ApplyJsonOverrides(
                cfg, LoadJsonFile(json_override_path));
        }

        auto logger = integrated_demo::CreateAsyncLogger(
            "integrated_demo", cfg.log_level);
        logger->info("loaded config {}", cfg.ToJson().dump());

        integrated_demo::RestServer server(cfg, logger);
        if (!server.Listen()) {
            logger->error("server listen failed");
            return 3;
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
