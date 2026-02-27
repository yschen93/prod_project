#include <string>

#include <absl/strings/str_cat.h>
#include <absl/time/clock.h>
#include <absl/time/time.h>
#include <httplib.h>
#include <nlohmann/json.hpp>
#include <spdlog/spdlog.h>
#include <yaml-cpp/yaml.h>

int main()
{
  const std::string s = absl::StrCat("a", "b");
  const absl::Time now = absl::Now();
  const auto nanos = absl::ToUnixNanos(now);

  nlohmann::json j;
  j["s"] = s;
  j["nanos"] = nanos;

  YAML::Node n;
  n["k"] = "v";

  spdlog::info("verify {}", j.dump());

  httplib::Client cli("http://127.0.0.1:1");
  (void)cli;
  return 0;
}

