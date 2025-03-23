/**
 * 数据库错误类
 * 用于封装和标准化数据库操作中的错误
 */

export class DatabaseError extends Error {
  errorCode: number;
  operation: string;

  constructor(message: string, operation: string, errorCode: number = -1) {
    super(message);
    this.name = 'DatabaseError';
    this.errorCode = errorCode;
    this.operation = operation;
  }

  toString(): string {
    return `DatabaseError[${this.errorCode}]: ${this.message} (在操作 ${this.operation} 中)`;
  }
}
