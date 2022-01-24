/*******************************************************/
/*                     Cminus Parser                   */
/*                                                     */
/*******************************************************/

/*********************DEFINITIONS***********************/
%{
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <string.h>
#include <util/general.h>
#include <util/symtab.h>
#include <util/symtab_stack.h>
#include <util/dlink.h>
#include <util/string_utils.h>
#include <unistd.h>

#define SYMTABLE_SIZE 100
#define SYMTAB_VALUE_FIELD "value"

/*********************EXTERNAL DECLARATIONS***********************/

EXTERN(void,Cminus_error,(const char*));

EXTERN(int,Cminus_lex,(void));

char *fileName;

extern int Cminus_lineno;

extern FILE *Cminus_in;

SymTable symtab;

%}

%name-prefix="Cminus_"
%defines

%start Program

%token AND
%token ELSE
%token EXIT
%token FOR
%token IF 		
%token INTEGER 
%token NOT 		
%token OR 		
%token READ
%token WHILE
%token WRITE
%token LBRACE
%token RBRACE
%token LE
%token LT
%token GE
%token GT
%token EQ
%token NE
%token ASSIGN
%token COMMA
%token SEMICOLON
%token LBRACKET
%token RBRACKET
%token LPAREN
%token RPAREN
%token PLUS
%token TIMES
%token IDENTIFIER
%token DIVIDE
%token RETURN
%token STRING	
%token INTCON
%token MINUS

%left OR
%left AND
%left NOT
%left LT LE GT GE NE EQ
%left PLUS MINUS
%left TIMES DIVDE

%union {
	char *name; //name is both the name and value in the case of a string
	int index; //index in sym table
	int value; //value of integer data
}
%type <name> IDENTIFIER StringConstant STRING
%type <index> Variable
%type <value> INTCON Expr SimpleExpr AddExpr MulExpr Factor Constant

/***********************PRODUCTIONS****************************/
%%
Program		: Procedures 
		{
			//printf("<Program> -> <Procedures>\n");
		}
	  	| DeclList Procedures
		{
			//printf("<Program> -> <DeclList> <Procedures>\n");
		}
          ;

Procedures 	: ProcedureDecl Procedures
		{
			//printf("<Procedures> -> <ProcedureDecl> <Procedures>\n");
		}
	   	|
		{
			//printf("<Procedures> -> epsilon\n");
		}
	   	;

ProcedureDecl : ProcedureHead ProcedureBody
		{
			//printf("<ProcedureDecl> -> <ProcedureHead> <ProcedureBody>\n");
		}
              ;

ProcedureHead : FunctionDecl DeclList 
		{
			//printf("<ProcedureHead> -> <FunctionDecl> <DeclList>\n");
		}
	      | FunctionDecl
		{
			//printf("<ProcedureHead> -> <FunctionDecl>\n");
		}
              ;

FunctionDecl :  Type IDENTIFIER LPAREN RPAREN LBRACE 
		{
			//printf("<FunctionDecl> ->  <Type> <IDENTIFIER> <LP> <RP> <LBR>\n"); 
		}
	      	;

ProcedureBody : StatementList RBRACE
		{
			//printf("<ProcedureBody> -> <StatementList> <RBR>\n");
		}
	      ;


DeclList 	: Type IdentifierList  SEMICOLON 
		{
			//printf("<DeclList> -> <Type> <IdentifierList> <SC>\n");
		}		
	   	| DeclList Type IdentifierList SEMICOLON
	 	{
			//printf("<DeclList> -> <DeclList> <Type> <IdentifierList> <SC>\n");
	 	}
          	;


IdentifierList 	: VarDecl  
		{
			//printf("<IdentifierList> -> <VarDecl>\n");
		}
						
                | IdentifierList COMMA VarDecl
		{
			//printf("<IdentifierList> -> <IdentifierList> <CM> <VarDecl>\n");
		}
                ;

VarDecl 	: IDENTIFIER
		{ 
			//printf("<VarDecl> -> <IDENTIFIER\n");
		}
		| IDENTIFIER LBRACKET INTCON RBRACKET
                {
			//printf("<VarDecl> -> <IDENTIFIER> <LBK> <INTCON> <RBK>\n");
		}
		;

Type     	: INTEGER 
		{ 
			//printf("<Type> -> <INTEGER>\n");
		}
                ;

Statement 	: Assignment 
		{ 
			//printf("<Statement> -> <Assignment>\n");
		}
                | IfStatement
		{ 
			//printf("<Statement> -> <IfStatement>\n");
		}
		| WhileStatement
		{ 
			//printf("<Statement> -> <WhileStatement>\n");
		}
                | IOStatement 
		{ 
			//printf("<Statement> -> <IOStatement>\n");
		}
		| ReturnStatement
		{ 
			//printf("<Statement> -> <ReturnStatement>\n");
		}
		| ExitStatement	
		{ 
			//printf("<Statement> -> <ExitStatement>\n");
		}
		| CompoundStatement
		{ 
			//printf("<Statement> -> <CompoundStatement>\n");
		}
                ;

Assignment      : Variable ASSIGN Expr SEMICOLON /*EDIT*/
		{
			//printf("<Assignment> -> <Variable> <ASSIGN> <Expr> <SC>\n");
			SymPutFieldByIndex(symtab, $1, SYMTAB_VALUE_FIELD, (Generic)$3);
		}
                ;
				
IfStatement	: IF TestAndThen ELSE CompoundStatement
		{
			//printf("<IfStatement> -> <IF> <TestAndThen> <ELSE> <CompoundStatement>\n");
		}
		| IF TestAndThen
		{
			//printf("<IfStatement> -> <IF> <TestAndThen>\n");
		}
		;
		
				
TestAndThen	: Test CompoundStatement
		{
			//printf("<TestAndThen> -> <Test> <CompoundStatement>\n");
		}
		;
				
Test		: LPAREN Expr RPAREN
		{
			//printf("<Test> -> <LP> <Expr> <RP>\n");
		}
		;
	

WhileStatement  : WhileToken WhileExpr Statement
		{
			//printf("<WhileStatement> -> <WhileToken> <WhileExpr> <Statement>\n");
		}
                ;
                
WhileExpr	: LPAREN Expr RPAREN
		{
			//printf("<WhileExpr> -> <LP> <Expr> <RP>\n");
		}
		;
				
WhileToken	: WHILE
		{
			//printf("<WhileToken> -> <WHILE>\n");
		}
		;


IOStatement     : READ LPAREN Variable RPAREN SEMICOLON /*EDIT*/
		{
			//printf("<IOStatement> -> <READ> <LP> <Variable> <RP> <SC>\n");
			//read in value and store in sym table
			char *var = malloc(256);
			read(0, var, 256);
			SymPutFieldByIndex(symtab, $3, SYMTAB_VALUE_FIELD, (Generic)atoi(var));
			free(var);
		}
                | WRITE LPAREN Expr RPAREN SEMICOLON
		{
			//printf("<IOStatement> -> <WRITE> <LP> <Expr> <RP> <SC>\n");
			//write value
			printf("%d\n", $3);
		}
                | WRITE LPAREN StringConstant RPAREN SEMICOLON         
		{
			//printf("<IOStatement> -> <WRITE> <LP> <StringConstant> <RP> <SC>\n");
			//write value, stripping " from start and end
			char *val = $3;
			val = val+1;
			val[strlen(val)-1] = '\0';
			printf("%s\n", val);
		}
                ;

ReturnStatement : RETURN Expr SEMICOLON
		{
			//printf("<ReturnStatement> -> <RETURN> <Expr> <SC>\n");
		}
                ;

ExitStatement 	: EXIT SEMICOLON
		{
			//printf("<ExitStatement> -> <EXIT> <SC>\n");
		}
		;

CompoundStatement : LBRACE StatementList RBRACE
		{
			//printf("<CompoundStatement> -> <LBR> <StatementList> <RBR>\n");
		}
                ;

StatementList   : Statement
		{		
			//printf("<StatementList> -> <Statement>\n");
		}
                | StatementList Statement
		{		
			//printf("<StatementList> -> <StatementList> <Statement>\n");
		}
                ;

Expr            : SimpleExpr /*EDIT*/
		{
			//printf("<Expr> -> <SimpleExpr>\n");
			$$ = $1;
		}
                | Expr OR SimpleExpr 
		{
			//printf("<Expr> -> <Expr> <OR> <SimpleExpr> \n");
			$$ = $1 | $3;
		}
                | Expr AND SimpleExpr 
		{
			//printf("<Expr> -> <Expr> <AND> <SimpleExpr> \n");
			$$ = $1 && $3;
		}
                | NOT SimpleExpr 
		{
			//printf("<Expr> -> <NOT> <SimpleExpr> \n");
			$$ = !$2;
		}
                ;

SimpleExpr	: AddExpr /*EDIT*/
		{
			//printf("<SimpleExpr> -> <AddExpr>\n");
			$$ = $1;
		}
                | SimpleExpr EQ AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <EQ> <AddExpr> \n");
			$$ = $1 == $3;
		}
                | SimpleExpr NE AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <NE> <AddExpr> \n");
			$$ = $1 != $3;
		}
                | SimpleExpr LE AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <LE> <AddExpr> \n");
			$$ = $1 <= $3;
		}
                | SimpleExpr LT AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <LT> <AddExpr> \n");
			$$ = $1 < $3;
		}
                | SimpleExpr GE AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <GE> <AddExpr> \n");
			$$ = $1 >= $3;
		}
                | SimpleExpr GT AddExpr
		{
			//printf("<SimpleExpr> -> <SimpleExpr> <GT> <AddExpr> \n");
			$$ = $1 > $3;
		}
                ;

AddExpr		:  MulExpr      /*EDIT*/      
		{
			//printf("<AddExpr> -> <MulExpr>\n");
			$$ = $1;
		}
                |  AddExpr PLUS MulExpr
		{
			//printf("<AddExpr> -> <AddExpr> <PLUS> <MulExpr> \n");
			$$ = $1 + $3;
		}
                |  AddExpr MINUS MulExpr
		{
			//printf("<AddExpr> -> <AddExpr> <MINUS> <MulExpr> \n");
			$$ = $1 - $3;
		}
                ;

MulExpr		:  Factor /*EDIT*/
		{
			//printf("<MulExpr> -> <Factor>\n");
			$$ = $1;
		}
                |  MulExpr TIMES Factor
		{
			//printf("<MulExpr> -> <MulExpr> <TIMES> <Factor> \n");
			$$ = $1 * $3;
		}
                |  MulExpr DIVIDE Factor
		{
			//printf("<MulExpr> -> <MulExpr> <DIVIDE> <Factor> \n");
			$$ = $1 / $3;
		}		
                ;
				
Factor          : Variable /*EDIT*/
		{ 
			//printf("<Factor> -> <Variable>\n");
			$$ = (int)SymGetFieldByIndex(symtab, $1, SYMTAB_VALUE_FIELD);
		}
                | Constant
		{ 
			//printf("<Factor> -> <Constant>\n");
			$$ = $1;
		}
                | IDENTIFIER LPAREN RPAREN
       	{	
			//printf("<Factor> -> <IDENTIFIER> <LP> <RP>\n");
		}
         	| LPAREN Expr RPAREN
		{
			//printf("<Factor> -> <LP> <Expr> <RP>\n");
			$$ = $2;
		}
                ;  

Variable        : IDENTIFIER /*EDIT*/
		{
			//printf("<Variable> -> <IDENTIFIER>\n");
			$$ = (int)SymIndex(symtab, $1);
		}
                | IDENTIFIER LBRACKET Expr RBRACKET    
               	{
			//printf("<Variable> -> <IDENTIFIER> <LBK> <Expr> <RBK>\n");
               	}
                ;			       

StringConstant 	: STRING /*EDIT*/
		{ 
			//printf("<StringConstant> -> <STRING>\n");
			$$ = $1;
		}
                ;

Constant        : INTCON /*EDIT*/
		{ 
			//printf("<Constant> -> <INTCON>\n");
			$$ = $1;
		}
                ;

%%


/********************C ROUTINES *********************************/

void Cminus_error(const char *s)
{
  fprintf(stderr,"%s: line %d: %s\n",fileName,Cminus_lineno,s);
}

int Cminus_wrap() {
	return 1;
}

static void initialize(char* inputFileName) {

	symtab = SymInit(SYMTABLE_SIZE);
	SymInitField(symtab, SYMTAB_VALUE_FIELD, (Generic)-1, NULL);

	Cminus_in = fopen(inputFileName,"r");
	if (Cminus_in == NULL) {
		fprintf(stderr,"Error: Could not open file %s\n",inputFileName);
		exit(-1);
	}

	char* dotChar = rindex(inputFileName,'.');
	int endIndex = strlen(inputFileName) - strlen(dotChar);
	char *outputFileName = nssave(2,substr(inputFileName,0,endIndex),".s");
	stdout = freopen(outputFileName,"w",stdout);
	if (stdout == NULL) {
		fprintf(stderr,"Error: Could not open file %s\n",outputFileName);
		exit(-1);
	}

}

static void finalize() {

    fclose(Cminus_in);
    fclose(stdout);
	//kill sym table
    SymKillField(symtab, SYMTAB_VALUE_FIELD);
	SymKill(symtab);

}

int main(int argc, char** argv)

{	
	fileName = argv[1];
	initialize(fileName);
	
    Cminus_parse();
  
  	finalize();
  
  	return 0;
}
/******************END OF C ROUTINES**********************/
