// Run by WSL (Ubuntu 20.04) terminal: make ; ./calc


/****************
	PROLOGUE
*****************/
%{
#include "StructureVariable.c"
#include <math.h>
#include <stdio.h>
#include <glib.h>

GHashTable* t_hash;

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
%token VIEWVARS
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
%type <v> Assign
%type <l> AssignOP

%type <v> Expr
%type <v> Term
%type <v> Func
%type <v> Fact
%type <v> Primary


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

Assign:
	VAR AssignOP Expr 
		{ 
			Variable* var = GetVar($1);

			if (var == NULL) {
				if(strcmp($2, "=") == 0){
					// Se for o operador ATTR(=), adicionamos na memória
					AddVar($1, $3);
					//g_hash_table_insert(t_hash, $1, &$3);
					$$ = $3;
				} else {
					// Se não for operador ATTR (=) é retornado um erro
					char strerror[100] = "A variável '"; strcat(strerror, $1); strcat(strerror, "' NÃO foi declarada.");
					yyerror(strerror); 
					YYABORT;
				}
			} else {
				// Se var existir, atualizamos baseado no operador
				double result;

				if(strcmp($2, "=") == 0)
					result = $3;
				else if(strcmp($2, "+=") == 0)
					result = var->value + $3;
				else if(strcmp($2, "-=") == 0)
					result = var->value - $3;
				else if(strcmp($2, "/=") == 0)
					result = var->value / $3;
				else if(strcmp($2, "*=") == 0)
					result = var->value *= $3;
				else if(strcmp($2, "%=") == 0)
					result = (int)var->value % (int)$3;
				
				UpdateVar($1, result);
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
	| SUB Func { $$ = -$2; }

Func: 
	Primary { $$ = $1; }
	| LOG LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = log10($3)/log10($5); printf("Log de %f na base %f\n", $3, $5); }
	| SQRT LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = pow($3, 1/$5); printf("Raiz (indice: %f) de %f\n", $5, $3); }
	| POW LBRACKET Expr SEPARATOR Expr RBRACKET { $$ = pow($3, $5); printf("%f elevado a %f\n", $3, $5); }

Primary:
	VAR 
		{ 
			// Busca na lista se o Lexeme já existe
			Variable* var = GetVar($1);
			//gpointer* value = g_hash_table_lookup(t_hash, $1);
			if (var != NULL) {
				// Se existir ele é retornado
				$$ = var->value;
			} else {
				// Se não existir ocorre um erro
				char strerror[100] = "A variável '";
				strcat(strerror, $1);
				strcat(strerror, "' NÃO foi declarada.");
				yyerror(strerror);
				YYABORT;
			}	
		}
	| NUMBER { $$ = $1; }
	| LBRACKET Expr RBRACKET { $$ = $2; printf("(%f)\n", $2); }

	
%%

int yyerror(char const *s) {
	printf("%s\n", s);
}

int main() {
	t_hash = g_hash_table_new(g_str_hash, g_str_equal);

    int ret = yyparse();
    if (ret){
	    fprintf(stderr, "%d error found.\n",ret);
    }

    return 0;
}

