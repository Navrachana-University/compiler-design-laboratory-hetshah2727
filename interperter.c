#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINES 100
#define MAX_VARS 100
#define MAX_LABEL_LEN 10
#define MAX_NAME_LEN 50

typedef struct {
    char name[MAX_NAME_LEN];
    int value;
} Variable;

typedef struct {
    char label[MAX_LABEL_LEN];
    int line_number;
} Label;

Variable vars[MAX_VARS];
int var_count = 0;

Label labels[MAX_LINES];
int label_count = 0;

char* trim(char* str) {
    while (isspace(*str)) str++;
    char* end = str + strlen(str) - 1;
    while (end > str && isspace(*end)) *end-- = '\0';
    return str;
}

int get_var_value(const char* name) {
    for (int i = 0; i < var_count; ++i)
        if (strcmp(vars[i].name, name) == 0)
            return vars[i].value;

    fprintf(stderr, "Undefined variable: %s\n", name);
    exit(1);
}

void set_var_value(const char* name, int value) {
    for (int i = 0; i < var_count; ++i) {
        if (strcmp(vars[i].name, name) == 0) {
            vars[i].value = value;
            return;
        }
    }
    strcpy(vars[var_count].name, name);
    vars[var_count].value = value;
    var_count++;
}

int is_number(const char* str) {
    while (*str) {
        if (!isdigit(*str++)) return 0;
    }
    return 1;
}

int eval_operand(const char* op) {
    return is_number(op) ? atoi(op) : get_var_value(op);
}

int find_label_line(const char* label) {
    for (int i = 0; i < label_count; ++i)
        if (strcmp(labels[i].label, label) == 0)
            return labels[i].line_number;
    fprintf(stderr, "Label not found: %s\n", label);
    exit(1);
}

void preprocess_labels(char* lines[], int count) {
    for (int i = 0; i < count; ++i) {
        char* colon = strchr(lines[i], ':');
        if (colon) {
            *colon = '\0';
            strcpy(labels[label_count].label, trim(lines[i]));
            labels[label_count].line_number = i + 1;
            label_count++;
        }
    }
}

int main() {
    char* lines[MAX_LINES];
    char buffer[256];
    int line_count = 0;

    FILE* file = fopen("output.txt", "r");
    if (!file) {
        perror("Failed to open output.txt");
        return 1;
    }

    while (fgets(buffer, sizeof(buffer), file)) {
        lines[line_count] = strdup(trim(buffer));
        line_count++;
    }
    fclose(file);

    preprocess_labels(lines, line_count);

    for (int i = 0; i < line_count; ++i) {
        char* line = lines[i];
        if (strchr(line, ':')) continue; // Skip label-only lines

        if (strncmp(line, "print", 5) == 0) {
            char var[MAX_NAME_LEN];
            sscanf(line, "print %s", var);
            printf("%d\n", get_var_value(var));
        }
        else if (strncmp(line, "ifFalse", 7) == 0) {
            char cond[MAX_NAME_LEN], label[MAX_LABEL_LEN];
            sscanf(line, "ifFalse %s goto %s", cond, label);
            if (!get_var_value(cond)) {
                i = find_label_line(label) - 1;
            }
        }
        else if (strncmp(line, "goto", 4) == 0) {
            char label[MAX_LABEL_LEN];
            sscanf(line, "goto %s", label);
            i = find_label_line(label) - 1;
        }
        else if (strchr(line, '=')) {
            char dest[MAX_NAME_LEN], op1[MAX_NAME_LEN], op2[MAX_NAME_LEN], op;
            if (sscanf(line, "%s = %s %c %s", dest, op1, &op, op2) == 4) {
                int v1 = eval_operand(op1);
                int v2 = eval_operand(op2);
                int result;
                switch (op) {
                    case '+': result = v1 + v2; break;
                    case '-': result = v1 - v2; break;
                    case '*': result = v1 * v2; break;
                    case '/': result = v1 / v2; break;
                    case '<': result = v1 < v2; break;
                    case '>': result = v1 > v2; break;
                    default:
                        fprintf(stderr, "Unknown operator: %c\n", op);
                        exit(1);
                }
                set_var_value(dest, result);
            }
            else if (strstr(line, "<=") || strstr(line, ">=") || strstr(line, "==") || strstr(line, "!=")) {
                char dest[MAX_NAME_LEN], op1[MAX_NAME_LEN], op2[MAX_NAME_LEN];
                if (sscanf(line, "%s = %s", dest, buffer) == 2) {
                    char* p;
                    if ((p = strstr(buffer, "<="))) {
                        *p = '\0'; p += 2;
                        set_var_value(dest, eval_operand(buffer) <= eval_operand(p));
                    } else if ((p = strstr(buffer, ">="))) {
                        *p = '\0'; p += 2;
                        set_var_value(dest, eval_operand(buffer) >= eval_operand(p));
                    } else if ((p = strstr(buffer, "=="))) {
                        *p = '\0'; p += 2;
                        set_var_value(dest, eval_operand(buffer) == eval_operand(p));
                    } else if ((p = strstr(buffer, "!="))) {
                        *p = '\0'; p += 2;
                        set_var_value(dest, eval_operand(buffer) != eval_operand(p));
                    }
                }
            }
            else {
                char var[MAX_NAME_LEN], val[MAX_NAME_LEN];
                sscanf(line, "%s = %s", var, val);
                set_var_value(var, eval_operand(val));
            }
        }
    }

    // Free memory
    for (int i = 0; i < line_count; i++) free(lines[i]);

    return 0;
}
