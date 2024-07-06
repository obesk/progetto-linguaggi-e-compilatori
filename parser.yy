%skeleton "lalr1.cc" /* -*- C++ -*- */
%require "3.2"
%defines

%define api.token.constructor
%define api.location.file none
%define api.value.type variant
%define parse.assert

%code requires {
  # include <string>
  #include <exception>
  class driver;
  class RootAST;
  class ExprAST;
  class NumberExprAST;
  class VariableExprAST;
  class CallExprAST;
  class FunctionAST;
  class SeqAST;
  class PrototypeAST;
  class BlockExprAST;
  class VarBindingAST;
  class GlobalVariableAST;
  class VariableAssignmentAST;
  class BinaryExprAST;
  class UnaryExprAST;
  class IfExprAST;
  class ForExprAST;
}

// The parsing context.
%param { driver& drv }

%locations

%define parse.trace
%define parse.error verbose

%code {
# include "driver.hpp"
}

%define api.token.prefix {TOK_}
%token
  END  0  "end of file"
  SEMICOLON  ";"
  COMMA      ","
  MINUS      "-"
  PLUS       "+"
  INC        "++"
  STAR       "*"
  SLASH      "/"
  LPAREN     "("
  RPAREN     ")"
  QMARK	     "?"
  COLON      ":"
  LT         "<"
  EQ         "=="
  ASSIGN     "="
  LBRACE     "{"
  RBRACE     "}"
  EXTERN     "extern"
  GLOB       "global"
  IF         "if"
  ELSE       "else"
  FOR        "for"
  DEF        "def"
  VAR        "var"
;

%token <std::string> IDENTIFIER "id"
%token <double> NUMBER "number"
%type <ExprAST*> exp
%type <ExprAST*> idexp
%type <ExprAST*> ternaryop
%type <ExprAST*> expif
%type <ExprAST*> expfor
%type <ExprAST*> condexp
%type <std::vector<ExprAST*>> optexp
%type <std::vector<ExprAST*>> explist
%type <RootAST*> program
%type <RootAST*> top
%type <FunctionAST*> definition
%type <PrototypeAST*> external
%type <GlobalVariableAST*> global
%type <VariableAssignmentAST*> assignment
%type <VariableAssignmentAST*> increment
%type <PrototypeAST*> proto
%type <std::vector<std::string>> idseq
%type <BlockExprAST*> blockexp
%type <SeqAST*> statements
%type <std::vector<VarBindingAST*>> vardefs
%type <VarBindingAST*> binding


%%
%start startsymb;

startsymb:
program                 { drv.root = $1; }

program:
  %empty                { $$ = new SeqAST(nullptr, nullptr); }
|  top ";" program      { $$ = new SeqAST($1,$3); };

top:
%empty                  { $$ = nullptr; }
| definition            { $$ = $1; }
| external              { $$ = $1; }
| global                { $$ = $1; };

definition:
  "def" proto exp       { $$ = new FunctionAST($2,$3); $2->noemit(); };

external:
  "extern" proto        { $$ = $2; };

global:
  "global" "id"         { $$ = new GlobalVariableAST($2); };

proto:
  "id" "(" idseq ")"    { $$ = new PrototypeAST($1,$3);  };

idseq:
  %empty                { std::vector<std::string> args; $$ = args; }
| "id" idseq            { $2.insert($2.begin(),$1); $$ = $2; };

%right "=";
%left ":";
%left "<" "==";
%left "+" "-";
%left "*" "/";
%right "++";
%nonassoc LOWER_THAN_ELSE;
%nonassoc "else";

exp:
  exp "+" exp           { $$ = new BinaryExprAST('+',$1,$3); }
| exp "-" exp           { $$ = new BinaryExprAST('-',$1,$3); }
| exp "*" exp           { $$ = new BinaryExprAST('*',$1,$3); }
| exp "/" exp           { $$ = new BinaryExprAST('/',$1,$3); }
| idexp                 { $$ = $1; }
| "-" exp               { $$ = new UnaryExprAST('-', $2); }
| "(" exp ")"           { $$ = $2; }
| "number"              { $$ = new NumberExprAST($1); }
| ternaryop             { $$ = $1; }
| expif                 { $$ = $1; }
| expfor                { $$ = $1; }
| blockexp              { $$ = $1; }
| assignment            { $$ = $1; };

assignment:
  "id" "=" exp        { $$ = new VariableAssignmentAST($1, $3); };
| increment           { $$ = $1; }

increment:
  "++" "id"           { $$ = new VariableAssignmentAST($2, new BinaryExprAST('+', new VariableExprAST($2), new NumberExprAST(1))); }

statements:
  exp                   { $$ = new SeqAST($1, nullptr); }
| statements ";" exp           { $$ = new SeqAST($1, $3); };

blockexp:
  "{" statements "}"             { $$ = new BlockExprAST({}, $2); }
| "{" vardefs ";" statements "}" { $$ = new BlockExprAST($2, $4); };

vardefs:
  binding                 { std::vector<VarBindingAST*> definitions;
                            definitions.push_back($1);
                            $$ = definitions; }
| vardefs ";" binding     { $1.push_back($3);
                            $$ = $1; }
                            
binding:
  "var" "id" "=" exp      { $$ = new VarBindingAST($2,$4); }
                      
expif:
  "if" "(" condexp ")" exp %prec LOWER_THAN_ELSE { $$ = new IfExprAST($3, $5, nullptr); }
| "if" "(" condexp ")" exp "else" exp            { $$ = new IfExprAST($3, $5, $7); };

expfor:
  "for" "(" binding ";" condexp ";" assignment ")" exp %prec LOWER_THAN_ELSE { $$ = new ForExprAST($3, $5, $7, $9); }


ternaryop:
  condexp "?" exp ":" exp { $$ = new IfExprAST($1,$3,$5); }

condexp:
  exp "<" exp           { $$ = new BinaryExprAST('<',$1,$3); }
| exp "==" exp          { $$ = new BinaryExprAST('=',$1,$3); }

idexp:
  "id"                  { $$ = new VariableExprAST($1); }
| "id" "(" optexp ")"   { $$ = new CallExprAST($1,$3); };

optexp:
  %empty                { std::vector<ExprAST*> args; $$ = args; }
| explist               { $$ = $1; };

explist:
  exp                   { std::vector<ExprAST*> args; args.push_back($1); $$ = args; }
| exp "," explist       { $3.insert($3.begin(), $1); $$ = $3; };
 
%%

void
yy::parser::error (const location_type& l, const std::string& m)
{
  std::cerr << l << ": " << m << '\n';
}
