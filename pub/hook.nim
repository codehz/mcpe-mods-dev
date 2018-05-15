import macros

proc mcpelauncher_hook*(a: pointer, b: pointer, c: pointer) {. importc .}

macro hook*(head, body: untyped): untyped =
  head.expectKind(nnkStrLit)
  let linkName = head.strVal
  body.expectLen(1)
  let procDef = body[0]
  let funcName = procDef[0].ident
  let params = procDef[3]
  let fnBody = procDef[6]

  let reflIdent = ident($funcName & "Refl")
  let origIdent = ident($funcName & "Orig")
  let realIdent = newIdentNode(funcName)
  
  nnkStmtList.newTree(
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        reflIdent,
        nnkPar.newTree(
          nnkProcTy.newTree(
            params,
            nnkPragma.newTree(
              newIdentNode("cdecl")
            )
          )
        ),
        newNilLit()
      )
    ),
    nnkProcDef.newTree(
      origIdent,
      newEmptyNode(),
      newEmptyNode(),
      params,
      nnkPragma.newTree(
        nnkExprColonExpr.newTree(
          newIdentNode("importc"),
          newLit(linkName)
        )
      ),
      newEmptyNode(),
      newEmptyNode()
    ),
    nnkProcDef.newTree(
      realIdent,
      newEmptyNode(),
      newEmptyNode(),
      params,
      nnkPragma.newTree(
        newIdentNode("exportc")
      ),
      newEmptyNode(),
      fnBody
    ),
    nnkCall.newTree(
      newIdentNode("mcpelauncher_hook"),
      origIdent,
      realIdent,
      nnkCall.newTree(
        newIdentNode("addr"),
        reflIdent
      )
    )
  )