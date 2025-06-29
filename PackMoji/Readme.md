好的，我们进入开发的深水区。

这份全新的README将包含更多开发者关心的技术细节、架构决策和代码层面的规范。随后的“开发看板 (Canvas)”则将这些任务可视化，方便您在Cursor中跟进项目进度。

---

## PackMoji: 技术架构与开发看板 (README v2.0)

本文档是 `PackMoji` 项目的核心技术指南，为开发人员提供端到端的架构设计、代码规范和任务规划。

### 1. 项目愿景与技术哲学

* **愿景**: 成为旅行者首选的、最智能、最省心的打包清单助手。
* **技术哲学**:
    * **后端即服务 (BaaS)**: 后端是无状态的、纯粹的逻辑“大脑”，不处理用户会话。
    * **前端即体验 (FaaE)**: 前端是原生、流畅、体验至上的交互层。
    * **数据驱动**: 所有的智能推荐都必须基于结构化的数据模型和清晰的算法。

### 2. 系统架构

(架构图保持不变，但组件的内部将更复杂)
```
[ Frontend: iOS App ] <--(HTTPS/JSON)--> [ Backend: Server ] <--(API Calls)--> [ External Weather API ]
```

### 3. 技术栈 (Tech Stack)

* **Frontend**: Swift 5, SwiftUI, Combine (用于状态管理与异步处理)
* **Backend**: Node.js v20+, Express.js v4, (可选: TypeScript)
* **外部服务**: OpenWeatherMap (或同类天气API)

### 4. 详细技术设计

#### 4.1. 后端架构 (Backend Architecture)

建议采用清晰、可扩展的分层目录结构：

```
/backend
|-- /config          # 配置文件 (如 a'pi keys, a'pi urls)
|-- /models          # 数据模型 (定义物品数据库结构)
|-- /routes          # 路由定义 (如 checklist.routes.js)
|-- /controllers     # 控制器 (处理HTTP请求，调用服务)
|-- /services        # 核心业务逻辑 (如 recommendation.service.js)
|-- /utils           # 工具函数 (如 a'pi wrappers, error handlers)
|-- items.json       # V1 版本的物品数据库
|-- .env             # 环境变量
|-- server.js        # 服务器入口文件
```

**核心中间件 (Middleware):**

* `cors`: 处理跨域请求。
* `express.json()`: 解析JSON请求体。
* `express-rate-limit`: 限制API请求频率，防止滥用。
* `errorHandler`: 自定义全局错误处理中间件。

**推荐引擎算法 - V1 (评分机制):**

这是推荐引擎的核心。对于物品数据库中的每一项，我们根据“旅行情景”计算一个匹配分数。

```javascript
// In recommendation.service.js
function calculateMatchScore(item, tripContext) {
    let score = 0;
    const WEIGHTS = { temp: 0.4, weather: 0.3, activity: 0.3 };

    // 1. 温度评分
    const { temp_min, temp_max } = item.attributes;
    if (tripContext.avgTemp >= temp_min && tripContext.avgTemp <= temp_max) {
        score += WEIGHTS.temp;
    }

    // 2. 天气状况评分
    const itemWeather = item.attributes.weather_condition;
    if (itemWeather.includes(tripContext.weather)) {
        score += WEIGHTS.weather;
    }

    // 3. 活动评分
    const itemActivities = item.attributes.activities;
    const userActivities = tripContext.activities;
    // 每匹配一个用户活动，就增加一部分分数
    const activityMatchCount = userActivities.filter(ua => itemActivities.includes(ua)).length;
    if (activityMatchCount > 0) {
        score += WEIGHTS.activity * (activityMatchCount / userActivities.length);
    }

    return score;
}
```
最终，我们会筛选出分数高于某个阈值（例如 `0.6`）的所有物品，并按分数高低或类别进行组织。

#### 4.2. 前端架构 (Frontend Architecture)

建议采用 MVVM (Model-View-ViewModel) 设计模式。

**目录结构:**

```
/PackMoji (Xcode Project)
|-- /Models           # 数据模型 (Codable Structs)
|-- /Views            # SwiftUI 视图
|   |-- /Home
|   |   |-- HomeView.swift
|   |   |-- TagCloudView.swift
|   |-- /Checklist
|   |   |-- ChecklistView.swift
|   |   |-- ChecklistCategoryView.swift
|   |   |-- ChecklistItemRow.swift
|-- /ViewModels       # 视图模型
|   |-- HomeViewModel.swift
|   |-- ChecklistViewModel.swift
|-- /Services         # 网络服务、数据持久化
|   |-- APIService.swift
|-- /Utils            # 工具与扩展
```

**状态管理:**

* 使用 `Combine` 框架。ViewModel 遵循 `ObservableObject` 协议。
* UI相关的状态（如加载中、错误信息）使用 `@Published` 属性包装器，以便View可以自动更新。

**网络层 (`APIService.swift`):**

* 创建一个单例或可注入的 `APIService` 类，封装所有 `URLSession` 的网络请求逻辑。
* 使用泛型和 `Combine` 的 `Publisher` 来构建可复用的请求方法，处理JSON解码和错误。

### 5. API 与数据模型

#### 5.1. API 端点
(与上一版README相同，`POST /api/v1/generate-checklist`)

#### 5.2. 前端数据模型 (Swift Codable Structs)

```swift
// In Models/ChecklistResponse.swift
import Foundation

struct ChecklistResponse: Codable {
    let tripInfo: TripInfo
    let checklist: [ChecklistCategory]
}

struct TripInfo: Codable {
    let destinationName: String
    let durationDays: Int
    let weatherSummary: String
}

struct ChecklistCategory: Codable, Identifiable {
    let id = UUID() // For SwiftUI lists
    let category: String
    let items: [ChecklistItem]

    // Handle custom key for SwiftUI list
    private enum CodingKeys: String, CodingKey {
        case category, items
    }
}

struct ChecklistItem: Codable, Identifiable {
    let id: String
    let emoji: String
    let name: String
    let quantity: Int?
}
```

---

## PackMoji 开发任务看板 (Canvas)

这是一个可视化的任务列表，用于追踪V1版本的开发进度。

| 状态 (Status)       | 任务 (Task)                                                                                             | 负责人 (Owner) | 备注 (Notes)                                                                      |
| ------------------- | ------------------------------------------------------------------------------------------------------- | -------------- | --------------------------------------------------------------------------------- |
| **🚀 V1 待办 (To Do)** |                                                                                                         |                |                                                                                   |
|                     | `[Data]` **构建初始物品数据库 `items.json`** | Product/Dev    | **最高优先级**。至少包含50个带详细属性的物品，覆盖所有类别。                      |
|                     | `[Backend]` 实现天气API服务封装                                                                           | Backend Dev    | 缓存机制可选，但建议加入。                                                        |
|                     | `[Backend]` 开发评分制推荐引擎算法                                                                        | Backend Dev    | `calculateMatchScore` 函数是核心。                                                |
|                     | `[Backend]` 创建并测试 `/generate-checklist` API 路由和控制器                                             | Backend Dev    | 需要完整的请求验证。                                                              |
|                     | `[Frontend]` 使用SwiftUI搭建 `HomeView` 的静态UI                                                          | iOS Dev        | 参照 `home.html` 实现像素级还原。                                                 |
|                     | `[Frontend]` 创建可复用的 `TagCloudView` 组件                                                             | iOS Dev        |                                                                                   |
|                     | `[Frontend]` 创建 `ChecklistView`、`ChecklistCategoryView` 和 `ChecklistItemRow` 的静态UI                   | iOS Dev        | 参照 `checklist.html`。                                                         |
|                     | `[Frontend]` 实现 `APIService` 并完成与后端API的对接                                                      | iOS Dev        |                                                                                   |
|                     | `[Frontend]` 在 `HomeViewModel` 中集成API调用与页面跳转逻辑                                               | iOS Dev        | 处理加载中(loading)和错误(error)状态。                                            |
|                     | `[Frontend]` 实现 `ChecklistView` 的数据绑定和勾选交互逻辑                                                | iOS Dev        |                                                                                   |
| **⏳ 进行中 (In Progress)** |                                                                                                         |                |                                                                                   |
|                     | `[Project]` **搭建前后端项目骨架** | Lead Dev       | 包括Git仓库、目录结构、基础依赖安装。                                             |
| **✅ 已完成 (Done)** |                                                                                                         |                |                                                                                   |
|                     | `[Design]` **完成产品核心流程的UI/UX设计与HTML原型** | Product/Design | `home.html` 和 `checklist.html` 已最终确认。                                    |
|                     | `[Product]` 确定V1版本核心功能范围                                                                        | Product        |                                                                                   |
| **🧊 未来计划 (Backlog)** |                                                                                                         |                |                                                                                   |
|                     | `[Feature]` 用户账户系统与历史清单保存                                                                  |                |                                                                                   |
|                     | `[Feature]` 用户自定义/编辑清单功能                                                                     |                |                                                                                   |
|                     | `[Feature]` 清单分享功能                                                                                  |                |                                                                                   |
|                     | `[AI/ML]`  将推荐引擎从规则/评分制升级为机器学习模型                                                      |                |                                                                                   |
|                     | `[Feature]` 增加更多情景（如判断是城市还是山区）                                                          |                |                                                                                   |