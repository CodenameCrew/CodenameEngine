package;

using StringTools;

class Utils {
	// trace(evaluateArgsCondition("hello && (world || world)", ["hello", "world"])); //  true
	// trace(evaluateArgsCondition("hello && (!world || world)", ["hello"])); //  true
	// trace(evaluateArgsCondition("hello && (!world && world)", ["hello", "world"])); //  false
    public static function evaluateArgsCondition(condition:String, args:Array<String>):Bool {
        function evaluateToken(token:String):Bool {
            if (token.charAt(0) == '!') {
                return !args.contains(token.substr(1));
            } else {
                return args.contains(token);
            }
        }

        condition = condition.replace('&&', '&').replace('||', '|').replace(" ", "");

        final stack:Array<Dynamic> = [];
        var i = 0;

        while (i < condition.length) {
            final char = condition.charAt(i);

            switch (char) {
                case '(':
                    var j = i;
                    var balance = 1;
                    while (balance != 0) {
                        j++;
                        if (condition.charAt(j) == '(') balance++;
                        if (condition.charAt(j) == ')') balance--;
                    }
                    final subExpr = condition.substr(i + 1, j - i - 1);
                    stack.push(evaluateArgsCondition(subExpr, args));
                    i = j;
                case '&', '|':
                    stack.push(char);
                default:
                    var token = "";
                    while (i < condition.length && condition.charAt(i) != '&' && condition.charAt(i) != '|' && condition.charAt(i) != '(' && condition.charAt(i) != ')') {
                        token += condition.charAt(i);
                        i++;
                    }
                    stack.push(evaluateToken(token));
                    i--;
            }
            i++;
        }

        return evaluate(stack);
    }

    public static function evaluate(stack:Array<Dynamic>):Bool {
        var result = stack.shift();
        while (stack.length > 0) {
            final op = stack.shift();
            final next = stack.shift();
            switch(op) {
                case '&':
                    result = result && next;
                case '|':
                    result = result || next;
            }
        }
        return result;
    }
}
