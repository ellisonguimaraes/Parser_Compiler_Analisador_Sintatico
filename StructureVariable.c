#include "StructureVariable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Variable* head = NULL;

// Alocar um struct Variable e o retorna
Variable* Allocate()
{
    Variable* var = (Variable*)malloc(sizeof(Variable));
    var->next = NULL;
    return var;
}

// Percorre a lista encadeada procurando um Variable através do Lexeme
Variable* GetVar(char lexeme[50])
{
    Variable* current = head;

    while(current != NULL){
        if(!strcmp(current->lexeme, lexeme))
            return current;

        current = current->next;
    }

    return NULL;
}

// Adiciona uma nova Variable a lista encadeada (pelo HEAD)
void AddVar(char lexeme[50], double value)
{
    Variable* var = Allocate();
    strcpy(var->lexeme, lexeme);
    var->value = value;

    if(head != NULL)
        var->next = head;

    head = var;
}

// Atualiza o value de um Variable (procurando pelo lexeme)
void UpdateVar(char lexeme[50], double value)
{
    Variable* current = head;

    while(current != NULL){
        if(!strcmp(current->lexeme, lexeme))
        {
            current->value = value;
            break;
        }
    
        current = current->next;
    }
}

// Mostra toda a lista encadeada de Variable
void ShowAllVar()
{
    Variable* current = head;
    int count = 1;

    printf("\n***********************\nVariáveis do Sistema\n***********************\n");

    if(current == NULL){
        printf("Não há nenhuma variável armazenada. :( \n");
    }else{
        while(current != NULL){
            printf("%d: <%s, %f>\n", count, current->lexeme, current->value);
            current = current->next;
            count++;
        }
    }

    printf("***********************\n\n");
}