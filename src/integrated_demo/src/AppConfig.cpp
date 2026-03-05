#include "integrated_demo/AppConfig.h"

#include <fstream>
#include <sstream>

#include <absl/strings/ascii.h>
#include <absl/strings/str_split.h>
#include <absl/strings/strip.h>
#include <yaml-cpp/yaml.h>

namespace integrated_demo {

nlohmann::json AppConfig::ToJson() const
{
    nlohmann::json j;
    j["bind_host"] = bind_host;
    j["port"] = port;
    j["worker_threads"] = worker_threads;
    j["log_level"] = log_level;
    j["greeting"] = greeting;
    return j;
}

static std::optional<AppConfig>
LoadConfigFromYamlNode(const YAML::Node& root)
{
    if (!root || !root.IsMap()) {
        return std::nullopt;
    }

    AppConfig cfg;

    if (root["bind_host"]) {
        cfg.bind_host = root["bind_host"].as<std::string>();
    }
    if (root["port"]) {
        cfg.port = root["port"].as<int>();
    }
    if (root["worker_threads"]) {
        cfg.worker_threads = root["worker_threads"].as<int>();
    }
    if (root["log_level"]) {
        cfg.log_level = absl::AsciiStrToLower(
            root["log_level"].as<std::string>());
        cfg.log_level =
            std::string(absl::StripAsciiWhitespace(cfg.log_level));
    }
    if (root["greeting"]) {
        cfg.greeting = root["greeting"].as<std::string>();
    }

    if (!cfg.greeting.empty()) {
        std::vector<std::string> parts = absl::StrSplit(
            cfg.greeting, ' ', absl::SkipWhitespace());
        if (!parts.empty()) {
            parts[0] = absl::AsciiStrToUpper(parts[0]);
            cfg.greeting.clear();
            for (size_t i = 0; i < parts.size(); ++i) {
                if (i != 0) {
                    cfg.greeting.push_back(' ');
                }
                cfg.greeting.append(parts[i]);
            }
        }
    }

    return cfg;
}

std::optional<AppConfig>
LoadConfigFromYamlFile(const std::string& path)
{
    std::ifstream ifs(path);
    if (!ifs) {
        return std::nullopt;
    }

    std::stringstream buffer;
    buffer << ifs.rdbuf();
    return LoadConfigFromYamlString(buffer.str());
}

std::optional<AppConfig>
LoadConfigFromYamlString(const std::string& yaml_text)
{
    try {
        YAML::Node root = YAML::Load(yaml_text);
        return LoadConfigFromYamlNode(root);
    }
    catch (...) {
        return std::nullopt;
    }
}

void ApplyJsonOverrides(AppConfig& cfg,
                        const nlohmann::json& overrides)
{
    if (!overrides.is_object()) {
        return;
    }

    if (overrides.contains("bind_host") &&
        overrides["bind_host"].is_string()) {
        cfg.bind_host = overrides["bind_host"].get<std::string>();
    }
    if (overrides.contains("port") &&
        overrides["port"].is_number_integer()) {
        cfg.port = overrides["port"].get<int>();
    }
    if (overrides.contains("worker_threads") &&
        overrides["worker_threads"].is_number_integer()) {
        cfg.worker_threads =
            overrides["worker_threads"].get<int>();
    }
    if (overrides.contains("log_level") &&
        overrides["log_level"].is_string()) {
        cfg.log_level = absl::AsciiStrToLower(
            overrides["log_level"].get<std::string>());
        cfg.log_level =
            std::string(absl::StripAsciiWhitespace(cfg.log_level));
    }
    if (overrides.contains("greeting") &&
        overrides["greeting"].is_string()) {
        cfg.greeting = overrides["greeting"].get<std::string>();
    }
}

}  // namespace integrated_demo
