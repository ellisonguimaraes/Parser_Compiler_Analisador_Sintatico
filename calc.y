// Run by WSL (Ubuntu 20.04) terminal: make ; ./calc

/****************
	PROLOGUE
*****************/
%{
#include "StructureVariable.c"
#include <math.h>
#include <stdio.h>

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
%token E
%token EXCLUSIVEOR IMPLICATION
%token EQUAL DIFF
%token LESS LESSOREQUAL MORE MOREOREQUAL
%token ADD SUB
%token MUL DIV MOD
%token POW LOG SQRT
%token NOT
%token <v> NUMBER 
%token <l> VAR
%token NEG
%token LBRACKET RBRACKET
%token EOL

// Definição da Associatividade dos Tokens (padrão: right-to-left)
%left OR

// Definindo os tipos da gramática
%type <v> Rel
%type <v> RelLB

%type <v> Assign
%type <l> AssignOP

%type <v> Expr
%type <v> Term
%type <v> Func
%type <v> Fact
%type <v> Primary

%type <l> Unary
%type <v> End


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
	| Rel EOL { printf("Expressão: %f\n", $1); }
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

Rel:
	RelLB
	| Rel DIFF RelLB { $$ = $1 != $3; printf("%f == %f\n", $1, $3); }
	| Rel EQUAL RelLB { $$ = $1 == $3; printf("%f != %f\n", $1, $3); }

RelLB:
	Expr
	| RelLB MORE Expr { $$ = $1 > $3; printf("%f > %f\n", $1, $3); }
	| RelLB LESS Expr { $$ = $1 < $3; printf("%f < %f\n", $1, $3); }
	| RelLB MOREOREQUAL Expr { $$ = $1 >= $3; printf("%f >= %f\n", $1, $3); }
	| RelLB LESSOREQUAL Expr { $$ = $1 <= $3; printf("%f <= %f\n", $1, $3); }

Expr:
	Term { $$ = $1; }
	| Expr ADD Term { $$ = $1 + $3; printf("%f + %f\n", $1, $3); }
	| Expr SUB Term { $$ = $1 - $3; printf("%f - %f\n", $1, $3); }

Term:
	Fact { $$ = $1; }
	| Term MUL Fact { $$ = $1 * $3; printf("%f * %f\n", $1, $3); }
	| Term DIV Fact { $$ = $1 / $3; printf("%f / %f\n", $1, $3); }
	| Term MOD Fact { $$ = (int)$1 % (int)$3; printf("%d MOD %d\n", (int)$1, (int)$3); }

Fact:
	Func { $$ = $1; }
	| Unary Func  // ver porq coloquei end
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
	| LBRACKET End RBRACKET { $$ = $2; printf("(%f)\n", $2); }

Unary: 
	SUB { strcpy($$, "-"); }
	| NOT { strcpy($$, "!"); }

End:
	Rel { $$ = $1; }


	
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

