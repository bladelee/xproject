// 主应用 JS 文件，负责全局导入和配置
import "@hotwired/turbo-rails"
import "./controllers/index.js"
import { Turbo } from "@hotwired/turbo-rails"

Turbo.session.drive = false 