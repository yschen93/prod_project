#include <string>

#include <catch2/catch_test_macros.hpp>

#include <absl/strings/str_split.h>
#include <nlohmann/json.hpp>

#include "integrated_demo/AppConfig.h"

// NOLINTBEGIN(cppcoreguidelines-avoid-do-while)

TEST_CASE("YamlConfigLoad", "[config]")
{
    const std::string yaml_text = R"(
bind_host: "127.0.0.1"
port: 19090
worker_threads: 2
log_level: "INFO"
greeting: "hello world"
)";

    auto cfg_opt =
        integrated_demo::LoadConfigFromYamlString(yaml_text);
    REQUIRE(cfg_opt.has_value());
    // NOLINTBEGIN(bugprone-unchecked-optional-access)
    REQUIRE(cfg_opt->port == 19090);
    REQUIRE(cfg_opt->worker_threads == 2);
    REQUIRE(cfg_opt->log_level == "info");
    // NOLINTEND(bugprone-unchecked-optional-access)
}

TEST_CASE("JsonOverride", "[config]")
{
    integrated_demo::AppConfig cfg;
    nlohmann::json j;
    j["port"] = 20001;
    j["log_level"] = "debug";
    integrated_demo::ApplyJsonOverrides(cfg, j);
    REQUIRE(cfg.port == 20001);
    REQUIRE(cfg.log_level == "debug");
}

TEST_CASE("AbseilStringSplit", "[absl]")
{
    const std::vector<std::string> parts =
        absl::StrSplit("a,b,c", ',');
    REQUIRE(parts.size() == 3);
    REQUIRE(parts[0] == "a");
}

// NOLINTEND(cppcoreguidelines-avoid-do-while)
