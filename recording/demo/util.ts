export interface User {
  name: string;
  age: number;
}

export function greet(name: string): string {
  return `Hello, ${name}!`;
}

export function formatName(first: string, last: string): string {
  return `${first} ${last}`;
}

export function makeUser(name: string, age: number): User {
  return { name, age };
}
