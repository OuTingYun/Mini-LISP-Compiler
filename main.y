
%{
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
typedef struct Node{
	char *Type;
	char* AnsType; //Use to actuall Know the type of number;
	int number;
    struct Node *Children[100];
	struct Node *Parent;
	struct Node *FunExp;
	int ChildrenSize;
	int MaxChidrenSize;
	char *VariableName;
	// bool bool_val;
}NodePtr;
struct Node *Startnode;
struct Node *ParentNode=NULL;
struct Node *NewNode;
struct Node * VariableStack[100];
struct Node * FunStack[100];
struct Node *stack[999];
int Stacksize=-1, VSsize=-1, FSsize=-1, i=0;
void yyerror(const char *message);
void PutInParentStack_SetNewNodeParent();
void SetNode(char* Type,int val);
void SetInsNode(char* Type);
void Count(struct Node *node);
void Print();
void FunCall();
void PutAnsTypeNumber(struct Node *node,struct Node *Ansnode);
void TypeChecking(char* Type,struct Node *node);

int yylex();
int yywrap()
{
return 1;
}
%}
%union{
int ival;
char* word;
}

%token<ival> number1
%token<ival> boolean
%token<word> id
%token<word> lp
%token<word> rp

%token<word> print_op
%token<word> define_op
%token<word> if_op
%token<word> logical_op
%token<word> fun_op
%token<word> num_op

/* %type<word> LP
%type<word> RP */

%%
PROGRAM 	: PRO_STMT {/*printf("PRO_STMT\n");*/}
PRO_STMT 	: STMT {/*printf("STMT %d\n",count++);*/}
STMT	:STMT_EXP  | DEF_STMT|PRINT_STMT {/*printf("PRINT\n");*/} | STMT PRO_STMT{/*printf("PRO_STMT1 %d\n",count++);*/}
STMT_EXP:   EXP{/*printf("EXP\n");*/}
EXP		:   boolean{SetNode("bool",$1);}  |  number1{SetNode("int",$1);}  |  VARIABLE
		|	NUM_OP | LOGICAL_OP | IF_EXP |FUN_EXP |FUN_CALL
		|   EXP PRO_STMT	{/*printf("STMT_EXP EXP\n");*/}
		|	num_op{SetInsNode($1);}
DEF_STMT : LP define_op {SetInsNode($2);} VARIABLE EXP RP
PRINT_STMT : LP PRINT_OP EXP RP
PRINT_OP 	: print_op{SetInsNode($1);}
VARIABLE:id	{
	bool IsCreate=false;
	bool funpara=false;

	if(Startnode->ChildrenSize==1){ //Check whether the var is in the bag.
		if(!strcmp(Startnode->Children[1]->Children[0]->Type,"bag_funvar")){
			struct Node*bag=Startnode->Children[1]->Children[0];
			funpara=true;
			for(i=0;i<=bag->ChildrenSize;i++){
				if(!strcmp(bag->Children[i]->VariableName,$1)){// In the function, Let var in exp point to the var which is created in the bag.
					NewNode=bag->Children[i];
					SetNode("var",0);
					break;
				}
			}
		}}



	if(!funpara){ // Not in fun bag.
		for(i=0;i<=VSsize;i++){	//Check whether the var is Global var.
			if(!strcmp(VariableStack[i]->VariableName,$1)){
				IsCreate=true;
				if(!strcmp(ParentNode->Type,"define")){
					yyerror("Redefine Error");
					exit(0);}
				NewNode=VariableStack[i];
				SetNode("var",NewNode->number);
				break;
			}}
		if(!IsCreate){  //first appear.
			NewNode=malloc(sizeof(struct Node));
			SetNode("var",0);
			NewNode->VariableName=$1;}
	}}
	;
NUM_OP	: LP num_op{SetInsNode($2);} EXP EXP RP
		| LP num_op{SetInsNode($2);} RP
LOGICAL_OP : LP LOG_OP EXP EXP RP| LP LOG_OP EXP RP
LOG_OP	: logical_op{SetInsNode($1);}
IF_EXP	: LP if_op{SetInsNode($2);}EXP EXP EXP RP
FUN_EXP	: LP fun_op {SetInsNode($2);} FUN_IDs  EXP RP
FUN_IDs	: LP {SetInsNode("bag_funvar");} FUN_ID_id RP
	|LP {SetInsNode("bag_funvar");} RP
FUN_ID_id : FUN_ID_id_ids | FUN_ID_id FUN_ID_id_ids
FUN_ID_id_ids: id {SetNode("funvar",0);NewNode->VariableName=$1;}
	;
FUN_CALL	: LP FUN_EXP EXP RP| LP FUN_NAME EXP RP | LP FUN_NAME RP
FUN_NAME	: id { //This Fun must be created.
	for(i=0;i<=VSsize;i++){
		if(!strcmp(VariableStack[i]->VariableName,$1)){
			NewNode=VariableStack[i];
			ParentNode->Children[ParentNode->ChildrenSize]=NewNode;
			NewNode->Parent=ParentNode;
			SetInsNode("funname");
			break;
		}
	}}
LP		: lp { //Create an empty Node
	//Create Node (UnKnow Type)
	NewNode=malloc(sizeof(struct Node));
	// InitialNode
	NewNode->AnsType=NULL;
	NewNode->number=INT_MAX;
	NewNode->ChildrenSize=-1;
	NewNode->MaxChidrenSize=INT_MIN;
	NewNode->Parent=NULL;
	NewNode->FunExp=NULL;
	NewNode->Type="(";
	if(ParentNode==NULL){ //FirstNode
		Startnode=NewNode;
		Startnode->Parent=NULL;
		ParentNode=Startnode;
	}
	else PutInParentStack_SetNewNodeParent();} //OtherNode
RP		: rp {	//Return
	if(ParentNode->Parent!=NULL)ParentNode=ParentNode->Parent;

	else {
		//printf("RP\n");
		if((!strcmp(Startnode->Type,"print-num")||!strcmp(Startnode->Type,"print-bool"))&&Startnode->ChildrenSize>0){// call function with parameters inside
			int i;
			int p=Startnode->Children[1]->Children[0]->ChildrenSize;
			for(i=Startnode->ChildrenSize;i>1;i--){	//Count all thee parameters.
				PutAnsTypeNumber(Startnode->Children[1]->Children[0]->Children[p--],Startnode->Children[i]);}
			//Clear unuse Children.
			Startnode->Children[0]=Startnode->Children[1];
			Startnode->ChildrenSize=0;}
		else{//normal use
		// printf("heee\n");
			Count(Startnode);
			ParentNode=NULL;
			Stacksize=-1;
		}
	}}
%%
void TypeChecking(char* Type,struct Node *node){
	if(strcmp(Type,node->AnsType)) {
		if(!strcmp(Type,"int"))
			yyerror("Type Error: Expect 'number' but got 'boolean'.");
		else if(!strcmp(Type,"bool"))
			yyerror("Type Error: Expect 'boolean' but got 'number'.");
	}
}
void PutInParentStack_SetNewNodeParent(){
	ParentNode->ChildrenSize=ParentNode->ChildrenSize+1;
	ParentNode->Children[ParentNode->ChildrenSize]=NewNode;
	NewNode->Parent=ParentNode;}
void PutAnsTypeNumber(struct Node *node,struct Node *Ansnode){
	node->number=Ansnode->number;
	node->AnsType=Ansnode->AnsType;}
void SetNode(char*Type,int val){ //Put in ParentNode's Stack
	// var is malloc outside
	if(strcmp(Type,"var"))NewNode=malloc(sizeof(struct Node));
	char *c ="+";
	/* printf("size %lu",sizeof(c)+1); */

	//Initial
	NewNode->Type=Type;
	NewNode->ChildrenSize=-1;
	NewNode->number=val;
	PutInParentStack_SetNewNodeParent();

	//bool and int's  answer type is themselves
	if(!strcmp(Type,"int")||!strcmp(Type,"bool"))NewNode->AnsType=Type;}

void SetInsNode(char* Type){// Going Down, Let NewNode be ParentNode
	if(strcmp(Type,"bag_funvar")&&strcmp(Type,"funname")&&strcmp(NewNode->Type,"(")){
			printf("Syntax Error: Unexpect %s\n",Type);
			yyerror("  ");

	}
	NewNode->Type=Type;
	ParentNode=NewNode;
	NewNode=NULL;

	//Set MaxChidrenSize
	if(!strcmp(Type,"not"))ParentNode->MaxChidrenSize=1;
	else if(!strcmp(Type,"-")||!strcmp(Type,"/")||!strcmp(Type,"mod")||!strcmp(Type,">")||!strcmp(Type,"<"))ParentNode->MaxChidrenSize=2;
	else if(!strcmp(Type,"+")||!strcmp(Type,"*")||!strcmp(Type,"=")||!strcmp(Type,"and")||!strcmp(Type,"or")||!strcmp(Type,"bag_funvar"))ParentNode->MaxChidrenSize=INT_MAX;

	//Set AnsType
	if(!strcmp(Type,"and")||!strcmp(Type,"or")||!strcmp(Type,"not")||!strcmp(Type,">")||!strcmp(Type,"<")||!strcmp(Type,"="))ParentNode->AnsType="bool";
	else if(!strcmp(Type,"+")||!strcmp(Type,"-")||!strcmp(Type,"*")||!strcmp(Type,"/")||!strcmp(Type,"mod"))ParentNode->AnsType="int";}
void Count(struct Node *node){
	/* printf("%s\n",node->Type); */
	if(!strcmp(node->Type,"print-num")||!strcmp(node->Type,"print-bool")){	//Print has only one child.
		Count(node->Children[node->ChildrenSize]);
		Print(node);}
	else if(!strcmp(node->Type,"define")){	//Define has two Children 1)Name 2)exp
		//printf("define place\n");
		if(!strcmp(node->Children[1]->Type,"fun")){// Define for function, let Name's FunExp_pointer point to fun
			node->Children[0]->FunExp=node->Children[1];}
		else{	// Define for var. Put the EXP's count value into var.
			Count(node->Children[1]);
			/* printf("define x %d\n",node->Children[1]->number); */
			PutAnsTypeNumber(node->Children[0],node->Children[1]);}
		VariableStack[++VSsize]=node->Children[0];}
	else if(!strcmp(node->Type,"if")){	//If has three children 1)condition 2) true exp 2) false exp
		struct Node *buffer;
		Count(node->Children[0]);
		if(node->Children[0]->number){buffer=node->Children[1];}//true
		else{buffer=node->Children[2];}//false
		Count(buffer);
		PutAnsTypeNumber(node,buffer);}
	else if(!strcmp(node->Type,"fun")){	//Fun has two children 1)Bag for parameters 2)exp
		Count(node->Children[1]);
		PutAnsTypeNumber(node,node->Children[1]);}
	else if(!strcmp(node->Type,"funname")){	//fun_name's FunExp point to fun. All the children in fun_name are parameters.
		struct Node *bag=node->FunExp->Children[0];
		for(i=0;i<=node->ChildrenSize;i++){	//Count parameters which put into function
			//fun's parameter is function
			if(!strcmp(node->Children[i]->Type,"funname")){
				Count(node->Children[i]);}
			PutAnsTypeNumber(bag->Children[i],node->Children[i]);}//Put parameter in order
		Count(node->FunExp);
		PutAnsTypeNumber(node,node->FunExp);}
	else if(!strcmp(node->Type,"int")||!strcmp(node->Type,"bool")||!strcmp(node->Type,"var")) //Put leaf in stack which inorder to counpute
		stack[++Stacksize]=node;
	else if(node->ChildrenSize>=node->MaxChidrenSize){
		yyerror("Too many Children Error");
	}

	else {	//Num_Op | Logical_OP	Op's Children are operant

			if((node->ChildrenSize==-1)&&(!strcmp(node->Type,"+")||!strcmp(node->Type,"-")||!strcmp(node->Type,"*")||!strcmp(node->Type,"/")||!strcmp(node->Type,"mod")||!strcmp(node->Type,">")||!strcmp(node->Type,"<")||!strcmp(node->Type,"=")))
				yyerror("Need 2 arguments,but got 0");
			else if((node->ChildrenSize==-1)&&(!strcmp(node->Type,"not")))
				yyerror("Need 1 arguments,but got 0");
			else if((node->ChildrenSize==0)&&(!strcmp(node->Type,"+")||!strcmp(node->Type,"-")||!strcmp(node->Type,"*")||!strcmp(node->Type,"/")||!strcmp(node->Type,"mod")||!strcmp(node->Type,">")||!strcmp(node->Type,"<")||!strcmp(node->Type,"=")))
				yyerror("Need 2 arguments,but got 1");
		int size=0;
		int ans=0;
		while(size<=node->ChildrenSize){ //Count all operants.
			Count(node->Children[size++]);
			/* printf("sizwL: %d\n",node->Children[size-1]->number); */
		}
		if(node->MaxChidrenSize==1&&!strcmp(node->Type,"not")){
			TypeChecking("bool",node->Children[0]);
			if(node->number)ans=node->Children[0]->number-1;
			else ans=node->Children[0]->number+1;
			/* printf("%d\n",ans); */
			}
		else if(node->MaxChidrenSize==2){ // (- / mod > <)
			struct Node *num1_node=stack[Stacksize--];
			/* int num1=num1_node->number; */
			struct Node *num2_node=stack[Stacksize];
			/* int num2=num2_node->number; */
			int num1=node->Children[1]->number;
			int num0=node->Children[0]->number;
			TypeChecking("int",num1_node);
			TypeChecking("int",num2_node);
			if(!strcmp(node->Type,"-")){ans=num0-num1;}
			else if(!strcmp(node->Type,"/")){ans=num0/num1;}
			else if(!strcmp(node->Type,"mod")){ans=num0%num1;}
			else if(!strcmp(node->Type,">")){if(num0>num1)ans=1;else ans=0;}
			else if(!strcmp(node->Type,"<")){if(num0<num1)ans=1;else ans=0;}}
		else if(node->MaxChidrenSize==INT_MAX){	// (+ * =)
			//Count initial size
			size--;
			if(!strcmp(node->Type,"*")||!strcmp(node->Type,"=")||!strcmp(node->Type,"and"))ans=1;
			/* while(size>=0){ */
			for(i=0;i<=node->ChildrenSize;i++){
				struct Node* buffer=node->Children[i];
				if(!strcmp(node->Type,"and")||!strcmp(node->Type,"or"))TypeChecking("bool",buffer);
				else {/*printf("op %s %d\n",stack[Stacksize-size]->AnsType,stack[Stacksize-size]->number);*/TypeChecking("int",stack[Stacksize-size]);};
				if(!strcmp(node->Type,"+")){ans=ans+buffer->number;}
				else if(!strcmp(node->Type,"*")){ans=ans*buffer->number;}
				else if(!strcmp(node->Type,"=")){
					int j=i+1;
					while(j<=node->ChildrenSize){
						/* printf("%d\n",node->Children[j]->number); */
						if(buffer->number!=node->Children[j++]->number){
							ans=0;break;
							}
						}}
				if(!strcmp(node->Type,"and")){if(!buffer->number) ans=0;}
				else if(!strcmp(node->Type,"or")){if(buffer->number) ans=1;}
				/* size--; */
				}
			Stacksize=Stacksize-(node->ChildrenSize);}
		node->number=ans;

		/* printf("Count: %d",ans); */
		/* stack[Stacksize]=node; */
		}

		}
void Print(struct Node *node){
	if(!strcmp(node->Type,"print-num"))printf("%d\n",node->Children[0]->number);
	else if(node->Children[0]->number)printf("#t\n");
	else printf("#f\n");}
void yyerror(const char *message){
	fprintf(stderr, "%s\n",message);
	exit(0);
	}
int main(int argc, char *argv[]){
    yyparse();
    return(0);
}

