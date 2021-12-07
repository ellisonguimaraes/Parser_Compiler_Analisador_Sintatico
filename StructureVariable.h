#ifndef __STRUCTUREVARIABLE_H__
#define __STRUCTUREVARIABLE_H__

typedef struct StructureVariable
{
    char lexeme[50];
    double value;
    struct StructureVariable *next;
} Variable;

Variable* Allocate();
Variable* GetVar(char lexeme[50]);
void AddVar(char lexeme[50], double value);
void UpdateVar(char lexeme[50], double value);
void ShowAllVar();

#endif