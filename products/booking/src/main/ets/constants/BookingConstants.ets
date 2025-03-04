/**
 * 记账应用常量定义
 */
export class BookingConstants {
  /**
   * 字体权重 - 普通
   */
  static readonly FONT_WEIGHT_NORMAL: number = 400;

  /**
   * 字体权重 - 中等
   */
  static readonly FONT_WEIGHT_MEDIUM: number = 500;

  /**
   * 字体权重 - 粗体
   */
  static readonly FONT_WEIGHT_BOLD: number = 700;

  /**
   * 主路由路径
   */
  static readonly ACCOUNT_BOOK_ROUTE: string = 'pages/AccountBook';

  /**
   * 添加记录路由路径
   */
  static readonly ADD_RECORD_ROUTE: string = 'pages/AddRecord';

  /**
   * 统计分析路由路径
   */
  static readonly STATISTICS_ROUTE: string = 'pages/Statistics';

  /**
   * 我的页面路由路径
   */
  static readonly MINE_ROUTE: string = 'pages/Mine';

  /**
   * 收入类型
   */
  static readonly INCOME_TYPE: number = 1;
  static readonly RECORD_TYPE_INCOME: number = 1;

  /**
   * 支出类型
   */
  static readonly EXPENSE_TYPE: number = 2;
  static readonly RECORD_TYPE_EXPENSE: number = 2;

  /**
   * 数据库名称
   */
  static readonly DB_NAME: string = 'account_book.db';

  /**
   * 记录表名
   */
  static readonly TABLE_RECORD: string = 'records';

  /**
   * 类别表名
   */
  static readonly TABLE_CATEGORY: string = 'categories';

  /**
   * 默认图表高度
   */
  static readonly DEFAULT_CHART_HEIGHT: number = 300;

  /**
   * 图标映射常量
   */
  static readonly ICON_SALARY: string = 'ICON_SALARY';
  static readonly ICON_BONUS: string = 'ICON_BONUS';
  static readonly ICON_PARTTIME: string = 'ICON_PARTTIME';
  static readonly ICON_INVESTMENT: string = 'ICON_INVESTMENT';
  static readonly ICON_FOOD: string = 'ICON_FOOD';
  static readonly ICON_SHOPPING: string = 'ICON_SHOPPING';
  static readonly ICON_TRANSPORT: string = 'ICON_TRANSPORT';
  static readonly ICON_DINING: string = 'ICON_DINING';
  static readonly ICON_MEDICAL: string = 'ICON_MEDICAL';
  static readonly ICON_HOUSING: string = 'ICON_HOUSING';
  static readonly ICON_EDUCATION: string = 'ICON_EDUCATION';
  static readonly ICON_MISC: string = 'ICON_MISC';

  static readonly CARTOON_NEW_SUFFIX: string = '_cartoon_new'; // 新版轻卡通风格图标后缀
  static readonly EMPTY_ICON: string = 'app.media.ic_empty' + BookingConstants.CARTOON_NEW_SUFFIX; // 空图标资源
}
