#pragma once

#include <memory>

#include <httplib.h>
#include <spdlog/logger.h>

#include "integrated_demo/AppConfig.h"

namespace integrated_demo {

class RestServer {
public:
    RestServer(AppConfig cfg,
               std::shared_ptr<spdlog::logger> logger);

    bool Listen();
    void Stop();

private:
    void RegisterRoutes();

    AppConfig cfg_;
    std::shared_ptr<spdlog::logger> logger_;
    httplib::Server server_;
};

}  // namespace integrated_demo
