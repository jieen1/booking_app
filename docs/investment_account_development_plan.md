# 鸿蒙Next记账APP投资账本功能开发计划

## 总体目标

为鸿蒙Next记账APP增加投资账本功能，支持股票等投资产品的买卖记录，基于市场行情计算投资收益，并支持普通账本和投资账本间的相互转账。

## 第一阶段：基础架构实现

### 1. 数据模型扩展

- [x] **投资账本模型（InvestmentBookModel）**
  - [x] 继承自AccountBookModel基类
  - [x] 添加投资类型、初始投资金额等特有字段
  - [x] 实现JSON序列化和反序列化方法

- [x] **投资品种模型（InvestmentAssetModel）**
  - [x] 定义股票/基金代码、名称、类型等基本字段
  - [x] 定义购入价格、当前价格、持有数量等交易相关字段
  - [x] 实现盈亏金额和盈亏比例的计算方法

- [x] **投资交易记录模型（InvestmentTransactionModel）**
  - [x] 定义交易类型（买入、卖出）、交易价格、数量等字段
  - [x] 定义关联普通账本ID（资金来源/去向）
  - [x] 实现交易费用计算逻辑

- [x] **市场行情模型（MarketQuoteModel）**
  - [x] 定义股票/基金代码、当前价格、涨跌幅等字段
  - [x] 实现行情数据解析和格式化方法

### 2. 数据库表设计与实现

- [x] **投资账本表（investment_book）**
  - [x] 设计表结构，继承账本表通用字段
  - [x] 添加投资账本特有字段
  - [x] 实现创建表SQL

- [x] **投资品种表（investment_asset）**
  - [x] 设计表结构，包含品种基本信息和持仓信息
  - [x] 实现创建表SQL
  - [x] 添加索引优化查询

- [x] **投资交易记录表（investment_transaction）**
  - [x] 设计表结构，记录所有买入卖出交易
  - [x] 实现创建表SQL
  - [x] 添加关联普通流水记录的外键

- [x] **市场行情缓存表（market_quote）**
  - [x] 设计表结构，存储最近行情数据
  - [x] 实现创建表SQL
  - [x] 设计过期数据清理机制

### 3. 数据访问层实现

- [x] **投资账本数据访问类（InvestmentBookDBHelper）**
  - [x] 实现增删改查基本方法
  - [x] 实现账本余额更新方法
  - [x] 实现投资收益计算方法

- [x] **投资品种数据访问类（InvestmentAssetDBHelper）**
  - [x] 实现增删改查基本方法
  - [x] 实现按账本查询品种列表方法
  - [x] 实现持仓更新方法

- [x] **投资交易记录数据访问类（InvestmentTransactionDBHelper）**
  - [x] 实现增删改查基本方法
  - [x] 实现交易统计相关方法
  - [x] 实现与普通账本关联查询方法

- [x] **行情数据访问类（MarketQuoteDBHelper）**
  - [x] 实现增删改查基本方法
  - [x] 实现批量更新方法
  - [x] 实现数据过期检查和清理方法

## 类型修正方案

根据现有系统设计，账本类型（AccountBookModel.type）应使用如下常量区分不同类型账本：
- 1-现金账本 (ACCOUNT_TYPE_CASH)
- 2-银行卡 (ACCOUNT_TYPE_BANK_CARD)
- 3-支付宝 (ACCOUNT_TYPE_ALIPAY)
- 4-微信 (ACCOUNT_TYPE_WECHAT)
- 5-股票 (ACCOUNT_TYPE_STOCK)
- 999-其他 (ACCOUNT_TYPE_OTHER)

在现有实现中，错误地使用了 ACCOUNT_BOOK_TYPE_INVESTMENT (业务类型) 作为账本类型，需要进行以下修改：

### 需要修改的文件与修改内容

1. **InvestmentBookModel.ets**
   - 修改构造函数，使用 `BookingConstants.ACCOUNT_TYPE_STOCK(5)` 替代 `BookingConstants.ACCOUNT_BOOK_TYPE_INVESTMENT(1)`
   - 确保账本类型使用正确的股票账本类型

2. **InvestmentBookDBHelper.ets**
   - 修改 getAllInvestmentBooks、getInvestmentBookById 等方法中的查询条件
   - 将查询条件从 `type = BookingConstants.ACCOUNT_BOOK_TYPE_INVESTMENT` 改为 `type = BookingConstants.ACCOUNT_TYPE_STOCK`
   - 同时确保创建投资账本时使用正确的账本类型

3. **AccountBookHelper.ets**
   - 修改识别投资账本的逻辑（如果有）
   - 确保通过账本类型 5 (股票) 来识别投资账本

4. **数据库查询条件**
   - 修改所有使用账本类型筛选投资账本的查询条件
   - 将筛选条件从 `type = 1` (业务类型值) 改为 `type = 5` (股票账本类型值)

### 可能需要调整的功能

1. **账本类型判断逻辑**
   - 所有判断是否为投资账本的条件应使用 `type === BookingConstants.ACCOUNT_TYPE_STOCK`
   - 可能需要调整UI显示的账本图标和名称

2. **账本创建逻辑**
   - 创建投资账本的逻辑需要确保设置正确的账本类型
   - 同时可能需要增加业务类型字段，用于区分普通股票账本和投资专用账本

### 测试要点

1. 测试创建新投资账本后，账本类型是否正确
2. 测试现有投资账本的查询显示是否正常
3. 测试账本过滤和分类功能是否正常
4. 确保投资账本的特殊功能（如资产分析）正常工作
