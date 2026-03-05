#include "integrated_demo/Logging.h"

#include <memory>
#include <stdexcept>

#include <absl/strings/ascii.h>
#include <spdlog/async.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/spdlog.h>

namespace integrated_demo {

static spdlog::level::level_enum
ParseLevel(const std::string& level)
{
    const std::string lower = absl::AsciiStrToLower(level);
    if (lower == "trace")
        return spdlog::level::trace;
    if (lower == "debug")
        return spdlog::level::debug;
    if (lower == "info")
        return spdlog::level::info;
    if (lower == "warn")
        return spdlog::level::warn;
    if (lower == "error")
        return spdlog::level::err;
    if (lower == "critical")
        return spdlog::level::critical;
    return spdlog::level::info;
}

std::shared_ptr<spdlog::logger>
CreateAsyncLogger(const std::string& name,
                  const std::string& level)
{
    static std::once_flag init_flag;
    std::call_once(init_flag,
                   []() { spdlog::init_thread_pool(8192, 1); });

    auto console_sink =
        std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
    auto file_sink =
        std::make_shared<spdlog::sinks::basic_file_sink_mt>(
            "integrated_demo.log", true);
    std::vector<spdlog::sink_ptr> sinks{console_sink, file_sink};

    auto logger = std::make_shared<spdlog::async_logger>(
        name, sinks.begin(), sinks.end(), spdlog::thread_pool(),
        spdlog::async_overflow_policy::block);

    logger->set_level(ParseLevel(level));
    logger->set_pattern("%Y-%m-%d %H:%M:%S.%e [%t] [%l] %n: %v");
    logger->flush_on(spdlog::level::info);
    spdlog::register_logger(logger);
    return logger;
}

}  // namespace integrated_demo
