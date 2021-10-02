%debug

%define parse.error verbose
%define lr.type canonical-lr

%{
    #include "../lib/data_structures.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    extern int yylex();
    extern int yylex_destroy();
    extern void yyerror(const char* error);
    extern int line;
    extern int col;
    extern int lex_errors;
    extern FILE *yyin;
    int scope = 0;
    int params = 0;
    int args_ret = 0;
    int args = 0;
    int main_found = 0;
    int sin_errors = 0;
    int sem_errors = 0;
%}

%union{
    /*Token structure*/
    struct lexToken {
        char id[200];
        int line;
        int col;
    } lex;
    /*Tree node reference*/
    struct treeNode* treeNode;
}

/*Lexical Tokens*/
%token <lex> INT FLOAT TYPE ID LIST
%token <lex> IF ELSE FOR RETURN OUT IN
%token <lex> SS_OP MD_OP
%token <lex> LLOG_OP RLOG_OP
%token <lex> REL_OP ASS_OP
%token <lex> LIST_FUNC NIL LLIST_OP RLIST_OP
%token <lex> LITERAL
%token <lex> LB RB LP RP END SEPARATOR

/*Precedences*/
%left SS_OP
%left MD_OP
%left LLOG_OP 
%right LIST_FUNC
%right RLIST_OP
%right LLIST_OP
%right RLOG_OP
%right ELSE

/*Grammar types*/
%type <treeNode> start
%type <treeNode> program program_block
%type <treeNode> declar func_dclr params func
%type <treeNode> block statement expr operation val
%type <treeNode> flow_ctr if_else for return
%type <treeNode> ass_op log_op ulog_op rel_op ari_op md_op
%type <treeNode> input output
%type <treeNode> list_op list_con list_oper list_func
%type <treeNode> id
%type <treeNode> func_call func_params

/*Grammar*/
%%
start:
    program { syntaxTree = $$; }
;

program:
    program program_block {
        $$ = newNode("PROGRAM", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $2;
    }
    | 
    program_block { $$ = $1; }
;

program_block:
    declar END { $$ = $1; }
    | 
    func_dclr { $$ = $1; }
    |
    error { }
;

func_dclr:
    func LP params {
        updateParams(table, params);
        params = 0;
    } RP LB block RB {
        $$ = newNode("FUNCTION", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        $$->subtree3 = $7;
        if($$->subtree1->type == 1){
            if($$->subtree3->type == 1){
                $$->type = $$->subtree1->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree3->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree3->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree3->type == 2){
                $$->type = $$->subtree3->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree3->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 3){
            if($$->subtree3->type == 3){
                $$->type = $$->subtree1->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree3->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 4){
            if($$->subtree3->type == 3){
                $$->type = $$->subtree1->type;
            }else if($$->subtree3->type == 4){
                $$->type = $$->subtree3->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree3->type, $2.line, $2.col);
                sem_errors++;
            }
        }
    }
    |
    func LP {
        updateParams(table, params);
    } RP LB block RB {
        $$ = newNode("FUNCTION", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $6;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 3){
            if($$->subtree2->type == 3){
                $$->type = $$->subtree1->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 4){
            if($$->subtree2->type == 3){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 4){
                $$->type = $$->subtree2->type;
            }else{
                printf("Return type error: Function type is %d and return is %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        }
    }
;

params:
    params SEPARATOR declar {
        params++;
        $$ = newNode("PARAMS", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
    }
    |
    declar { 
        params++;
        $$ = $1;
    }
;

declar:
    TYPE ID {
        if(searchTable(table, $2.id, scope, 0, 1)) printf("Variable already declared\n");
        newSymbol(table, $2.id, $1.id, "VAR      ", $2.line, $2.col, scope, 0);   
        $$ = newNode(strcat(strcat($1.id," var "), $2.id), checkType(table, $2.id));
    }
    |
    TYPE LIST ID {
        if(searchTable(table, $3.id, scope, 0, 1)) printf("Variable already declared\n");
        newSymbol(table, $3.id, strcat($1.id," list"), "LIST VAR ",$3.line, $3.col, scope, 0);
        $$ = newNode(strcat(strcat($1.id," list "), $3.id), checkType(table, $3.id));
    }
    |
    error { }
;

func:
    TYPE ID {
        scope++;
        if(!strcmp($2.id, "main")) main_found = 1;
        if(searchTable(table, $2.id, scope, 1, 0)) printf("Function already declared\n");
        newSymbol(table, $2.id, $1.id, "FUNC     ", $2.line, $2.col, scope, -1);
        $$ = newNode(strcat(strcat($1.id," function "), $2.id), checkType(table, $2.id));
    }
    |
    TYPE LIST ID {
        scope++;
        if(!strcmp($3.id, "main")) main_found = 1;
        if(searchTable(table, $3.id, scope, 1, 0)) printf("Function already declared\n");
        newSymbol(table, $3.id, strcat($1.id," list"), "LIST FUNC", $3.line, $3.col, scope, -1);
        $$ = newNode(strcat(strcat($1.id," function list "), $3.id), checkType(table, $3.id));
    }
    |
    error { }
;

block:
    block statement {
        $$ = newNode("BLOCK", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $2;
        $$->type = $$->subtree2->type;
    }
    | 
    statement { $$ = $1; }
;

statement:
    expr END { $$ = $1; }
    |
    ass_op END{ $$ = $1; }
    |
    LB block RB { $$ = $2; }
    | 
    flow_ctr { $$ = $1; }
    |
    error  {  }
;

flow_ctr:
    if_else { $$ = $1; }
    |
    for { $$ = $1; }
    |
    return END { $$ = $1; }
;

expr:
    operation { $$ = $1; }
    |
    declar { $$ = $1; }
    |
    input { $$ = $1; }
    |
    output { $$ = $1; }
    |
    list_op { $$ = $1; }
    |
    list_func { $$ = $1; }
;

list_op:
    list_con { $$ = $1; }
    |
    list_oper { $$ = $1; }
;

if_else:
    IF LP operation RP statement %prec ELSE {
        $$ = newNode("IF", 0);
        $$->subtree1 = $3;
        $$->subtree2 = $5;
    }
    | 
    IF LP operation RP statement ELSE statement {
        $$ = newNode("IF ELSE", 0);
        $$->subtree1 = $3;
        $$->subtree2 = $5;
        $$->subtree3 = $7;
    }
    |
    IF error { }
;

for:
    FOR LP ass_op END operation END ass_op RP statement {
        $$ = newNode("FOR", 0);
        $$->subtree1 = $3;
        $$->subtree2 = $5;
        $$->subtree3 = $7;
        $$->subtree4 = $9;
    }
    |
    FOR error  {  }
;

return:
    RETURN expr {
        $$ = newNode("RETURN", 0);
        $$->subtree1 = $2;
        $$->type = $$->subtree1->type;
    }
;

ass_op:
    id ASS_OP expr {
        $$ = newNode("ASSIGN", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else{
                printf("Type error when assigning %d to %d. [%d, %d]\n", $$->subtree2->type, $$->subtree1->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error when assigning %d to %d. [%d, %d]\n", $$->subtree2->type, $$->subtree1->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 3){
            if($$->subtree2->type == 3){
                $$->type = $$->subtree1->type;
            }else{
                printf("Type error when assigning %d to %d. [%d, %d]\n", $$->subtree2->type, $$->subtree1->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 4){
            if($$->subtree2->type == 3){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 4){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error when assigning %d to %d. [%d, %d]\n", $$->subtree2->type, $$->subtree1->type, $2.line, $2.col);
                sem_errors++;
            }
        }
    }
;

list_con:
    expr RLIST_OP id {
        $$ = newNode("LIST OP", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1 || $$->subtree1->type == 2){
            if($$->subtree2->type == 3 || $$->subtree2->type == 4){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in list constructor with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in list constructor with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
;

list_oper:
    LLIST_OP expr {
        $$ = newNode("LIST OP", 0);
        $$->subtree1 = $2;
        if($$->subtree1->type == 3 || $$->subtree1->type == 4){
            $$->type = $$->subtree1->type;
        } else{
            printf("Type error in list operator with type %d. [%d, %d]\n", $$->subtree1->type, $1.line, $1.col);
            sem_errors++;
        }
    }
;

list_func:
    id LIST_FUNC expr {
        $$ = newNode("LIST FUNC", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1 || $$->subtree1->type == 2){
            if($$->subtree2->type == 3 || $$->subtree2->type == 4){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in list function with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in list function with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
;

operation:
    log_op { $$ = $1; }
;

input:
    IN LP id RP {
        $$ = newNode("IN", 0);
        $$->subtree1 = $3;
    }
;

output:
    OUT LP val RP {
        $$ = newNode("OUT", 0);
        $$->subtree1 = $3;
    }
    |
    OUT LP list_oper RP { 
        $$ = newNode("OUT", 0);
        $$->subtree1 = $3; 
    }
;

log_op:
    log_op LLOG_OP ulog_op {
        $$ = newNode("LOG OP", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = 1;
            }else if($$->subtree2->type == 2){
                $$->type = 1;
            }else{
                printf("Type error in logical operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = 1;
            }else if($$->subtree2->type == 2){
                $$->type = 1;
            }else{
                printf("Type error in logical operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in logical operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
    | 
    ulog_op { $$ = $1; }
;

ulog_op:
    RLOG_OP rel_op {
        $$ = newNode("LOG OP", 0);
        $$->subtree1 = $2;
        if($$->subtree1->type != 1 && $$->subtree1->type != 2){
            printf("Type error in logical operation with type %d. [%d, %d]\n", $$->subtree1->type, $1.line, $1.col);
            sem_errors++;
        }
        else $$->type = 1;
    }
    | 
    rel_op { $$ = $1; }
;

rel_op:
    rel_op REL_OP ari_op {
        $$ = newNode("REL OP", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = 1;
            }else if($$->subtree2->type == 2){
                $$->type = 1;
            }else{
                printf("Type error in relational operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = 1;
            }else if($$->subtree2->type == 2){
                $$->type = 1;
            }else{
                printf("Type error in relational operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in relational operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
    | 
    ari_op { $$ = $1; }
;

ari_op:
    ari_op SS_OP md_op {
        $$ = newNode("ARI SS OP", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
    | 
    md_op { $$ = $1; }
;

md_op:
    md_op MD_OP val {
        $$ = newNode("ARI MD OP", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
        if($$->subtree1->type == 1){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else if($$->subtree1->type == 2){
            if($$->subtree2->type == 1){
                $$->type = $$->subtree1->type;
            }else if($$->subtree2->type == 2){
                $$->type = $$->subtree2->type;
            }else{
                printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
                sem_errors++;
            }
        } else{
            printf("Type error in arithmetic operation with type %d and %d. [%d, %d]\n", $$->subtree1->type, $$->subtree2->type, $2.line, $2.col);
            sem_errors++;
        }
    }
    | 
    SS_OP val {
        $$ = newNode("NEGATIVE", 0);
        $$->subtree1 = $2;
        if($$->subtree1->type != 1 && $$->subtree1->type != 2){
            printf("Type error in assigning negative ti type %d. [%d, %d]\n", $$->subtree1->type, $1.line, $1.col);
            sem_errors++;
        }else{
             $$->type = $$->subtree1->type;
        }
    }
    | 
    val { $$ = $1; }
;

val:
    id { $$ = $1; }
    | 
    func_call { $$ = $1; }
    | 
    LP operation RP { $$ = $2; }
    |
    INT { $$ = newNode($1.id, 1); }
    | 
    FLOAT { $$ = newNode($1.id, 2); }
    | 
    NIL { $$ = newNode("NIL", 3); }
    |
    LITERAL { $$ = newNode($1.id, 0); }
;

func_call:
    ID LP func_params RP {
        if(!searchTable(table, $1.id, scope, 1, 1)) printf("Function not declared\n");
        else if(checkParams(table, $1.id) != args) printf("Function calls for different number of arguments\n");
        args = 0;
        $$ = newNode("CALL", checkType(table, $1.id));
        $$->subtree2 = $3;
    }
    | 
    ID LP RP {
        if(!searchTable(table, $1.id, scope, 1, 1)) printf("Function not declared\n");
        else if(checkParams(table, $1.id) != args) printf("Function calls for different number of arguments\n");
        args = 0;
        $$ = newNode("CALL", checkType(table, $1.id));
    }
;

id:
    ID { 
        if(!searchTable(table, $1.id, scope, 0, 0)) printf("Variable not declared\n");
        $$ = newNode($1.id, checkType(table, $1.id)); 
    }
;

func_params: 
    func_params SEPARATOR id{
        args++;
        $$ = newNode("PARAMS", 0);
        $$->subtree1 = $1;
        $$->subtree2 = $3;
    }
    | 
    id { 
        args++;
        $$ = $1; 
    }
;

%%

int main(int argc, char **argv){
    printf("────────────────────────────────────────\n");
    printf("Syntax analysis in file '%s'", argv[1]);
    printf("\n────────────────────────────────────────\n");

    yyin = fopen(argv[1], "r");

    yyparse();

    printf("\n");
    if(!main_found){
        printf("Main not found");
        sem_errors++;
    }

    printf("\n");
    printf("Syntax analysis finished with %d semantic error, %d syntax errors and %d lexical errors.\n", sem_errors, sin_errors, lex_errors);
    
    if(!sin_errors){
        showTree(syntaxTree, 0);
    }

    showTable(table);
    destroyTree();

    fclose(yyin);
    yylex_destroy();

    return 0;
}

void yyerror(const char* error) {
    printf("\n%s [%d, %d]\n", error, line, col);
    sin_errors++;
}
