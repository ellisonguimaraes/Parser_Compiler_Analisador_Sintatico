// Run by WSL (Ubuntu 20.04) terminal: make ; ./calc

/****************
	PROLOGUE
*****************/
%{
#include "StructureVariable.c"
#include <math.h>
#include <stdio.h>

// Definição da HashTable
hashtable* hash_table;

int yyerror (char const *s);
extern int yylex (void);
%}

// Definição dos tipos que podem ser assumidos pela variável yylval
%union
{
	double v;
	char l[50];
};

// Precedência e Associatividade baseado em C
// http://users.eecs.northwestern.edu/~wkliao/op-prec.htm

// Definição dos Tokens/Símbolos Terminais (e sua precedência)
%token VIEWHASHTABLE
%token SEPARATOR
%token ATTR ADDATTR SUBATTR MULATTR DIVATTR MODATTR
%token OR 
%token AND
%token EXCLUSIVEOR IMPLICATION
%token EQUAL DIFF
%token LESS LESSOREQUAL MORE MOREOREQUAL
%token ADD SUB
%token MUL DIV MOD
%token POW LOG SQRT
%token NOT
%token <v> NUMBER 
%token <l> VAR
%token LBRACKET RBRACKET
%token EOL

// Associatividade (padrão: right~left)
%left SEPARATOR
%left OR
%left AND
%left EXCLUSIVEOR IMPLICATION
%left EQUAL DIFF
%left LESS LESSOREQUAL MORE MOREOREQUAL
%left ADD SUB
%left MUL DIV MOD
%left LBRACKET RBRACKET

// Definindo os tipos da gramática
%type <v> Expr

%type <v> Log
%type <v> LogAND
%type <v> LogEXIM

%type <v> Rel
%type <v> RelLB

%type <v> Assign
%type <l> AssignOP

%type <v> Math
%type <v> Term
%type <v> Func
%type <v> Fact
%type <v> Primary

%type <l> Unary


%define parse.error verbose
%start Input


/****************************************************
	REGRAS DE PRODUÇÃO DA GRAMÁTICA DA LINGUAGEM
*****************************************************/
%%
Input: 
	/* empty */;
	| Input Line;

Line:	
	EOL
	| Assign EOL { printf("Atribuição: %f\n", $1); }
	| Expr EOL { printf("Expressão: %f\n", $1); }
	| VIEWHASHTABLE LBRACKET RBRACKET EOL { show_ht(hash_table); }

Assign:
	VAR AssignOP Expr 
		{ 
			node* n = get_value_ht(hash_table, $1);

			if(n == NULL)
			{
				if(strcmp($2, "=") == 0){
					// Se for o operador ATTR(=), adicionamos na tabela hash
					put_key_value_ht(hash_table, $1, $3);
					$$ = $3;
				} else {
					// Se não for operador ATTR(=) é retornado um erro
					char strerror[100] = "A variável '"; strcat(strerror, $1); strcat(strerror, "' NÃO foi declarada.");
					yyerror(strerror); 
					YYABORT;
				}

			} else {
				// Se n já existir, é feito somente a atualização com base no AssignOP escolhido
				double result;

				if(strcmp($2, "=") == 0)
					result = $3;
				else if(strcmp($2, "+=") == 0)
					result = n->value + $3;
				else if(strcmp($2, "-=") == 0)
					result = n->value - $3;
				else if(strcmp($2, "/=") == 0)
					result = n->value / $3;
				else if(strcmp($2, "*=") == 0)
					result = n->value *= $3;
				else if(strcmp($2, "%=") == 0)
					result = (int)n->value % (int)$3;
				
				put_key_value_ht(hash_table, $1, result);
				$$ = result;
			}
		}
			
AssignOP:
	ATTR { strcpy($$, "="); }
	| ADDATTR { strcpy($$, "+="); }
	| SUBATTR { strcpy($$, "-="); }
	| DIVATTR { strcpy($$, "/="); }
	| MULATTR { strcpy($$, "*="); }
	| MODATTR { strcpy($$, "%="); }

Expr: 
	Log;

Log: 
	LogAND
	| Log OR LogAND { $$ = $1 || $3; printf("%f || %f\n", $1, $3); }

LogAND: 
	LogEXIM
	| LogAND AND LogEXIM { $$ = $1 && $3; printf("%f && %f\n", $1, $3); }

LogEXIM: 
	Rel
	| LogEXIM EXCLUSIVEOR Rel { $$ = !!$1 ^ !!$3; printf("%f XOR %f\n", $1, $3); }
	| LogEXIM IMPLICATION Rel { $$ = !$1 || !!$3; printf("%f -> %f\n", $1, $3); }

Rel:
	RelLB
	| Rel DIFF RelLB { $$ = $1 != $3; printf("%f != %f\n", $1, $3); }
	| Rel EQUAL RelLB { $$ = $1 == $3; printf("%f == %f\n", $1, $3); }

RelLB:
	Math
	| RelLB MORE Math { $$ = $1 > $3; printf("%f > %f\n", $1, $3); }
	| RelLB LESS Math { $$ = $1 < $3; printf("%f < %f\n", $1, $3); }
	| RelLB MOREOREQUAL Math { $$ = $1 >= $3; printf("%f >= %f\n", $1, $3); }
	| RelLB LESSOREQUAL Math { $$ = $1 <= $3; printf("%f <= %f\n", $1, $3); }

Math:
	Term { $$ = $1; }
	| Math ADD Term { $$ = $1 + $3; printf("%f + %f\n", $1, $3); }
	| Math SUB Term { $$ = $1 - $3; printf("%f - %f\n", $1, $3); }

Term:
	Fact { $$ = $1; }
	| Term MUL Fact { $$ = $1 * $3; printf("%f * %f\n", $1, $3); }
	| Term DIV Fact { $$ = $1 / $3; printf("%f / %f\n", $1, $3); }
	| Term MOD Fact { $$ = (int)$1 % (int)$3; printf("%d MOD %d\n", (int)$1, (int)$3); }

Fact:
	Func { $$ = $1; }
	| Unary Func
		{ 
			if (strcmp($1, "-") == 0) {
				$$ = -$2;
				printf("-%f.\n", $2);
			} else if (strcmp($1, "!") == 0) {
				$$ = !$2;
				printf("Negação (!) de %f.\n", $2);
			}
		}

Func: 
	Primary { $$ = $1; }
	| LOG LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = log10($3)/log10($5); printf("Log de %f na base %f\n", $3, $5); }
	| SQRT LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = pow($3, 1/$5); printf("Raiz (indice: %f) de %f\n", $5, $3); }
	| POW LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = pow($3, $5); printf("%f elevado a %f\n", $3, $5); }

Primary:
	VAR 
		{
			node* n = get_value_ht(hash_table, $1);

			if(n == NULL)
			{
				// Se obter nulo, a variável não pertence a hashtable e é retornado um erro.
				char strerror[100] = "A variável '";
				strcat(strerror, $1);
				strcat(strerror, "' NÃO foi declarada.");
				yyerror(strerror);
				YYABORT;
			}
			
			printf("Acesso a variável %s.\n", n->key);
			$$ = n->value;
		}

	| NUMBER { $$ = $1; printf("Acesso ao número %f.\n", $1); }
	| LBRACKET Expr RBRACKET { $$ = $2; printf("(%f)\n", $2); }

Unary: 
	SUB { strcpy($$, "-"); }
	| NOT { strcpy($$, "!"); }

	
%%

int yyerror(char const *s) {
	printf("%s\n", s);
}

int main() {
	hash_table = build_hash_table();

	/*
	put_key_value_ht(hash_table, "oi", 50.5);
	put_key_value_ht(hash_table, "ola", 9);
	put_key_value_ht(hash_table, "mae", 7.5);
	put_key_value_ht(hash_table, "kk", 1.5);
	put_key_value_ht(hash_table, "ola", 20);

	 show_ht(hash_table);

	node* n = get_value_ht(hash_table, "kk");
	if(n != NULL) printf("Achamos %s com valor %f.\n", n->key, n->value);

	n = get_value_ht(hash_table, "haaa");
	if(n != NULL) printf("Achamos %s com valor %f.\n", n->key, n->value); else printf("Não achamos haaa!"); */

    int ret = yyparse();
    if (ret){
	    fprintf(stderr, "%d error found.\n",ret);
    }

    return 0;
}

