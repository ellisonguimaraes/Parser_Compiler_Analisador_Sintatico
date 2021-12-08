#ifndef __STRUCTUREVARIABLE_H__
#define __STRUCTUREVARIABLE_H__

// Tamanho da HashTable
static const int SIZE = 100;

// Representação do Nó
typedef struct structnode {
    char* key;
    double value;
    struct structnode* next;
} node;

// Representação da HashTable
typedef struct structhashtable {
    node** items;
} hashtable;

unsigned int hashfunction(char* key);
hashtable* build_hash_table();
node* build_pair(char* key, double value);
void put_key_value_ht(hashtable* ht, char* key, double value);
node* get_value_ht(hashtable* ht, char* key);
void show_ht(hashtable* ht);

#endif