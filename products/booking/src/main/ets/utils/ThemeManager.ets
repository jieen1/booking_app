import { BookingConstants } from '../constants/BookingConstants';
import preferences from '@ohos.data.preferences';

/**
 * 主题管理类，负责处理主题的切换、持久化和恢复
 */
export class ThemeManager {
  private static instance: ThemeManager;
  private themePref: preferences.Preferences | null = null;
  
  // 当前主题
  public currentTheme: string = BookingConstants.THEME_LIGHT;
  
  // 回调函数列表，用于通知组件主题变化
  private themeChangeCallbacks: Function[] = [];
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }
  
  /**
   * 初始化主题管理器
   * @returns Promise<void>
   */
  public async init(): Promise<void> {
    try {
      // 获取主题首选项
      this.themePref = await preferences.getPreferences(globalThis.getContext(), 'theme_preferences');
      
      // 恢复保存的主题，如果没有则使用默认主题
      const savedTheme = await this.themePref.get(BookingConstants.THEME_STORAGE_KEY, BookingConstants.THEME_LIGHT);
      this.currentTheme = savedTheme as string;
      
      // 应用主题
      this.applyTheme(this.currentTheme);
    } catch (error) {
      console.error('初始化主题管理器失败:', JSON.stringify(error));
      // 如果发生错误，使用默认主题
      this.applyTheme(BookingConstants.THEME_LIGHT);
    }
  }
  
  /**
   * 切换主题
   * @param theme 主题类型
   * @returns Promise<void>
   */
  public async switchTheme(theme: string): Promise<void> {
    // 应用主题设置
    this.applyTheme(theme);
    
    // 保存主题设置
    try {
      if (this.themePref) {
        await this.themePref.put(BookingConstants.THEME_STORAGE_KEY, theme);
        await this.themePref.flush();
      }
    } catch (error) {
      console.error('保存主题设置失败:', JSON.stringify(error));
    }
  }
  
  /**
   * 应用主题
   * @param theme 主题类型
   */
  private applyTheme(theme: string): void {
    // 更新当前主题
    this.currentTheme = theme;
    
    // 更新全局主题颜色
    BookingConstants.setTheme(theme);
    
    // 通知所有注册的回调
    this.notifyThemeChange();
  }
  
  /**
   * 注册主题变化回调
   * @param callback 回调函数
   * @returns number 回调ID，用于后续取消注册
   */
  public registerThemeChangeCallback(callback: Function): number {
    this.themeChangeCallbacks.push(callback);
    return this.themeChangeCallbacks.length - 1;
  }
  
  /**
   * 取消注册主题变化回调
   * @param callbackId 注册时返回的回调ID
   */
  public unregisterThemeChangeCallback(callbackId: number): void {
    if (callbackId >= 0 && callbackId < this.themeChangeCallbacks.length) {
      this.themeChangeCallbacks[callbackId] = () => {};
    }
  }
  
  /**
   * 通知主题变化
   */
  private notifyThemeChange(): void {
    for (const callback of this.themeChangeCallbacks) {
      try {
        callback(this.currentTheme);
      } catch (error) {
        console.error('执行主题变化回调失败:', JSON.stringify(error));
      }
    }
  }
  
  /**
   * 获取当前主题
   * @returns 当前主题
   */
  public getTheme(): string {
    return this.currentTheme;
  }
  
  /**
   * 是否为深色主题
   * @returns 是否为深色主题
   */
  public isDarkTheme(): boolean {
    return this.currentTheme === BookingConstants.THEME_DARK;
  }
}
