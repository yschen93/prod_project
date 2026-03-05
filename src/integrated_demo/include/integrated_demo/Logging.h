#pragma once

#include <memory>
#include <string>

#include <spdlog/logger.h>

namespace integrated_demo {

std::shared_ptr<spdlog::logger>
CreateAsyncLogger(const std::string& name,
                  const std::string& level);

}
