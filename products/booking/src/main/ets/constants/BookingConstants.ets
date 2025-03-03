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

  /**
   * 图标 - 轻卡通风格
   */
  static readonly CARTOON_SUFFIX: string = '_cartoon'; // 轻卡通风格图标后缀
  static readonly EMPTY_ICON: string = 'app.media.ic_empty' + BookingConstants.CARTOON_SUFFIX; // 空图标资源

  /**
   * 主题相关
   */
  // 主题类型常量
  static readonly THEME_LIGHT: string = 'light';
  static readonly THEME_DARK: string = 'dark';
  static readonly THEME_STORAGE_KEY: string = 'current_theme';

  /**
   * 浅色主题颜色
   */
  // 主色调 - 薄荷绿/青色
  static readonly LIGHT_PRIMARY_COLOR: string = '#5edfd0'; // 主要颜色
  static readonly LIGHT_PRIMARY_LIGHT_COLOR: string = '#e1f7f5'; // 浅色，用于选中状态背景
  static readonly LIGHT_SECONDARY_COLOR: string = '#FFA07A'; // 次要颜色（橙色，用于强调和操作按钮）
  
  // 背景色
  static readonly LIGHT_BG_COLOR: string = '#f3fdfb'; // 全局背景色
  static readonly LIGHT_BG_COLOR_WHITE: string = '#FFFFFF'; // 白色背景
  static readonly LIGHT_CARD_BG_COLOR: string = '#FFFFFF'; // 卡片背景色
  
  // 文字颜色
  static readonly LIGHT_TEXT_PRIMARY_COLOR: string = '#333333';  // 主要文字颜色（深灰色）
  static readonly LIGHT_TEXT_SECONDARY_COLOR: string = '#666666';  // 次要文字颜色（中灰色）
  static readonly LIGHT_TEXT_HINT_COLOR: string = '#999999';  // 提示文字颜色（浅灰色）
  static readonly LIGHT_TEXT_INCOME_COLOR: string = '#5edfd0';  // 收入文字颜色（青色）
  static readonly LIGHT_TEXT_EXPENSE_COLOR: string = '#FF9E80';  // 支出文字颜色（橙色）
  
  // 边框颜色
  static readonly LIGHT_BORDER_COLOR: string = '#E0E0E0';  // 边框颜色

  /**
   * 深色主题颜色
   */
  // 主色调 - 深青色
  static readonly DARK_PRIMARY_COLOR: string = '#1e7d71'; // 主要颜色
  static readonly DARK_PRIMARY_LIGHT_COLOR: string = '#2a5851'; // 浅色，用于选中状态背景
  static readonly DARK_SECONDARY_COLOR: string = '#FF7043'; // 次要颜色（橙色，用于强调和操作按钮）
  
  // 背景色
  static readonly DARK_BG_COLOR: string = '#121212'; // 全局背景色
  static readonly DARK_BG_COLOR_WHITE: string = '#1E1E1E'; // 深色背景
  static readonly DARK_CARD_BG_COLOR: string = '#2C2C2C'; // 卡片背景色
  
  // 文字颜色
  static readonly DARK_TEXT_PRIMARY_COLOR: string = '#E0E0E0';  // 主要文字颜色（亮白色）
  static readonly DARK_TEXT_SECONDARY_COLOR: string = '#B0B0B0';  // 次要文字颜色（亮灰色）
  static readonly DARK_TEXT_HINT_COLOR: string = '#707070';  // 提示文字颜色（暗灰色）
  static readonly DARK_TEXT_INCOME_COLOR: string = '#5edfd0';  // 收入文字颜色（青色）
  static readonly DARK_TEXT_EXPENSE_COLOR: string = '#FF9E80';  // 支出文字颜色（橙色）
  
  // 边框颜色
  static readonly DARK_BORDER_COLOR: string = '#3E3E3E';  // 边框颜色
  
  // 图表颜色 - 淡色系
  static readonly CHART_COLORS: string[] = [
    '#5edfd0', '#FFA07A', '#90CAF9', '#FFD54F', '#81C784',
    '#E57373', '#9575CD', '#4DB6AC', '#FFF176', '#F48FB1'
  ];
  
  /**
   * 当前主题（动态属性，默认为浅色主题）
   */
  // 主要颜色（默认为浅色）
  static PRIMARY_COLOR: string = BookingConstants.LIGHT_PRIMARY_COLOR;
  static PRIMARY_LIGHT_COLOR: string = BookingConstants.LIGHT_PRIMARY_LIGHT_COLOR;
  static SECONDARY_COLOR: string = BookingConstants.LIGHT_SECONDARY_COLOR;
  
  // 背景色
  static BG_COLOR: string = BookingConstants.LIGHT_BG_COLOR;
  static BG_COLOR_WHITE: string = BookingConstants.LIGHT_BG_COLOR_WHITE;
  static CARD_BG_COLOR: string = BookingConstants.LIGHT_CARD_BG_COLOR;
  
  // 文字颜色
  static TEXT_PRIMARY_COLOR: string = BookingConstants.LIGHT_TEXT_PRIMARY_COLOR;
  static TEXT_SECONDARY_COLOR: string = BookingConstants.LIGHT_TEXT_SECONDARY_COLOR;
  static TEXT_HINT_COLOR: string = BookingConstants.LIGHT_TEXT_HINT_COLOR;
  static TEXT_INCOME_COLOR: string = BookingConstants.LIGHT_TEXT_INCOME_COLOR;
  static TEXT_EXPENSE_COLOR: string = BookingConstants.LIGHT_TEXT_EXPENSE_COLOR;
  
  // 边框颜色
  static BORDER_COLOR: string = BookingConstants.LIGHT_BORDER_COLOR;
  
  /**
   * 切换主题
   * 
   * @param theme 主题类型，light 或 dark
   */
  static setTheme(theme: string): void {
    if (theme === BookingConstants.THEME_DARK) {
      // 设置为深色主题
      BookingConstants.PRIMARY_COLOR = BookingConstants.DARK_PRIMARY_COLOR;
      BookingConstants.PRIMARY_LIGHT_COLOR = BookingConstants.DARK_PRIMARY_LIGHT_COLOR;
      BookingConstants.SECONDARY_COLOR = BookingConstants.DARK_SECONDARY_COLOR;
      
      BookingConstants.BG_COLOR = BookingConstants.DARK_BG_COLOR;
      BookingConstants.BG_COLOR_WHITE = BookingConstants.DARK_BG_COLOR_WHITE;
      BookingConstants.CARD_BG_COLOR = BookingConstants.DARK_CARD_BG_COLOR;
      
      BookingConstants.TEXT_PRIMARY_COLOR = BookingConstants.DARK_TEXT_PRIMARY_COLOR;
      BookingConstants.TEXT_SECONDARY_COLOR = BookingConstants.DARK_TEXT_SECONDARY_COLOR;
      BookingConstants.TEXT_HINT_COLOR = BookingConstants.DARK_TEXT_HINT_COLOR;
      BookingConstants.TEXT_INCOME_COLOR = BookingConstants.DARK_TEXT_INCOME_COLOR;
      BookingConstants.TEXT_EXPENSE_COLOR = BookingConstants.DARK_TEXT_EXPENSE_COLOR;
      
      BookingConstants.BORDER_COLOR = BookingConstants.DARK_BORDER_COLOR;
    } else {
      // 设置为浅色主题（默认）
      BookingConstants.PRIMARY_COLOR = BookingConstants.LIGHT_PRIMARY_COLOR;
      BookingConstants.PRIMARY_LIGHT_COLOR = BookingConstants.LIGHT_PRIMARY_LIGHT_COLOR;
      BookingConstants.SECONDARY_COLOR = BookingConstants.LIGHT_SECONDARY_COLOR;
      
      BookingConstants.BG_COLOR = BookingConstants.LIGHT_BG_COLOR;
      BookingConstants.BG_COLOR_WHITE = BookingConstants.LIGHT_BG_COLOR_WHITE;
      BookingConstants.CARD_BG_COLOR = BookingConstants.LIGHT_CARD_BG_COLOR;
      
      BookingConstants.TEXT_PRIMARY_COLOR = BookingConstants.LIGHT_TEXT_PRIMARY_COLOR;
      BookingConstants.TEXT_SECONDARY_COLOR = BookingConstants.LIGHT_TEXT_SECONDARY_COLOR;
      BookingConstants.TEXT_HINT_COLOR = BookingConstants.LIGHT_TEXT_HINT_COLOR;
      BookingConstants.TEXT_INCOME_COLOR = BookingConstants.LIGHT_TEXT_INCOME_COLOR;
      BookingConstants.TEXT_EXPENSE_COLOR = BookingConstants.LIGHT_TEXT_EXPENSE_COLOR;
      
      BookingConstants.BORDER_COLOR = BookingConstants.LIGHT_BORDER_COLOR;
    }
  }
}
