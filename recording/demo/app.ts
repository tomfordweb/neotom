import { greet, makeUser } from "./util";

// `formatName` is intentionally NOT imported — ts_ls flags it (a live
// diagnostic) and offers an "Add import from ./util" code action on <leader>ca.
function describe(first: string, last: string): string {
  const full = formatName(first, last);
  return greet(full);
}

const user = makeUser("Ada", 36);
console.log(describe(user.name, "Lovelace"));
console.log(greet(user.name));
