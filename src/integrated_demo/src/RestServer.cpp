#include "integrated_demo/RestServer.h"

#include <absl/strings/match.h>
#include <absl/strings/str_format.h>
#include <absl/time/clock.h>
#include <absl/time/time.h>

namespace integrated_demo {

RestServer::RestServer(AppConfig cfg,
                       std::shared_ptr<spdlog::logger> logger)
    : cfg_(std::move(cfg)), logger_(std::move(logger))
{
    RegisterRoutes();
}

bool RestServer::Listen()
{
    logger_->info("starting server on {}:{}", cfg_.bind_host,
                  cfg_.port);
    return server_.listen(cfg_.bind_host, cfg_.port);
}

void RestServer::Stop()
{
    logger_->info("stopping server");
    server_.stop();
}

void RestServer::RegisterRoutes()
{
    server_.Get("/health", [this](const httplib::Request&,
                                  httplib::Response& res) {
        nlohmann::json j;
        j["status"] = "ok";
        res.set_content(j.dump(2), "application/json");
    });

    server_.Get("/time", [this](const httplib::Request&,
                                httplib::Response& res) {
        const absl::Time now = absl::Now();
        const std::string ts = absl::FormatTime(
            "%Y-%m-%dT%H:%M:%E*S%Ez", now, absl::LocalTimeZone());
        nlohmann::json j;
        j["time"] = ts;
        j["unix_ns"] = absl::ToUnixNanos(now);
        res.set_content(j.dump(2), "application/json");
    });

    server_.Post("/echo", [this](const httplib::Request& req,
                                 httplib::Response& res) {
        logger_->info("/echo content_type={} body_size={}",
                      req.get_header_value("Content-Type"),
                      req.body.size());

        nlohmann::json in;
        try {
            in = nlohmann::json::parse(req.body);
        }
        catch (...) {
            res.status = 400;
            res.set_content(R"({"error":"invalid json"})", "application/json");
            return;
        }

        nlohmann::json out;
        out["received"] = in;
        out["greeting"] = cfg_.greeting;
        if (in.contains("text") && in["text"].is_string()) {
            const std::string text = in["text"].get<std::string>();
            out["has_prefix_api"] = absl::StartsWith(text, "api");
            out["formatted"] =
                absl::StrFormat("%s | len=%d", text,
                                static_cast<int>(text.size()));
        }

        res.set_content(out.dump(2), "application/json");
    });

    server_.Get("/config", [this](const httplib::Request&,
                                  httplib::Response& res) {
        res.set_content(cfg_.ToJson().dump(2), "application/json");
    });
}

}  // namespace integrated_demo
