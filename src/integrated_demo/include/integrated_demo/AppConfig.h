#pragma once

#include <cstdint>
#include <optional>
#include <string>

#include <nlohmann/json.hpp>

namespace integrated_demo {

struct AppConfig {
    std::string bind_host{"127.0.0.1"};
    int port{18080};
    int worker_threads{4};
    std::string log_level{"info"};
    std::string greeting{"hello"};

    nlohmann::json ToJson() const;
};

std::optional<AppConfig>
LoadConfigFromYamlFile(const std::string& path);
std::optional<AppConfig>
LoadConfigFromYamlString(const std::string& yaml_text);
void ApplyJsonOverrides(AppConfig& cfg,
                        const nlohmann::json& overrides);

}  // namespace integrated_demo
