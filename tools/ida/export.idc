//
// export.idc - dump the IDA database to a text file for the decomp tooling.
//
// Written for IDA Free 5.0 (DOS MZ, 16-bit). Run with File > IDC file...
// and save the output as config/ida_export.txt in the project.
//
// Output is one record per line, tab separated:
//   ENTRY  <begin_ea>
//   SEG    <start> <end> <name>
//   FUNC   <start> <end> <flags> <name>
//   HEAD   <ea> <size> <kind> <flags>          kind: C=code D=data U=unknown
//   NAME   <ea> <user> <name>                  user: 1=user/auto name, 0=dummy
//   CREF   <from> <to> <type>                  code xrefs (calls/jumps, not flow)
//   DREF   <from> <to> <type>                  data xrefs (offsets, memory refs)
//   OP     <ea> <n> <optype> <value> <isoff> <text>
//   CMT    <ea> <text>                         regular comments
//
// All addresses are IDA linear addresses in hex.
//
#include <idc.idc>

static hex(x)
{
  return form("%X", x);
}

static clean(s)
{
  auto r, i, c;
  r = "";
  for (i = 0; i < strlen(s); i++) {
    c = substr(s, i, i + 1);
    if (c == "\t" || c == "\n" || c == "\r")
      c = " ";
    r = r + c;
  }
  return r;
}

static dump_xrefs(fh, ea)
{
  auto to;
  to = Rfirst0(ea);
  while (to != BADADDR) {
    fprintf(fh, "CREF\t%s\t%s\t%d\n", hex(ea), hex(to), XrefType());
    to = Rnext0(ea, to);
  }
  to = Dfirst(ea);
  while (to != BADADDR) {
    fprintf(fh, "DREF\t%s\t%s\t%d\n", hex(ea), hex(to), XrefType());
    to = Dnext(ea, to);
  }
}

static dump_ops(fh, ea, f)
{
  auto n, t, off;
  for (n = 0; n < 3; n++) {
    t = GetOpType(ea, n);
    if (t <= 0)
      break;
    off = 0;
    if (n == 0 && isOff0(f)) off = 1;
    if (n == 1 && isOff1(f)) off = 1;
    // o_mem=2 o_displ=4 o_imm=5 o_far=6 o_near=7
    if (off || t == 2 || t == 4 || t == 5 || t == 6 || t == 7) {
      fprintf(fh, "OP\t%s\t%d\t%d\t%s\t%d\t%s\n", hex(ea), n, t,
              hex(GetOperandValue(ea, n)), off, clean(GetOpnd(ea, n)));
    }
  }
}

static main()
{
  auto path, fh, seg, segend, ea, f, kind, nm, fn, cmt, nheads;

  path = AskFile(1, "ida_export.txt", "Save export as");
  if (path == "")
    return;
  fh = fopen(path, "w");
  if (fh == 0) {
    Warning("Cannot open %s", path);
    return;
  }

  fprintf(fh, "ENTRY\t%s\n", hex(BeginEA()));

  seg = FirstSeg();
  while (seg != BADADDR) {
    fprintf(fh, "SEG\t%s\t%s\t%s\n", hex(SegStart(seg)), hex(SegEnd(seg)),
            SegName(seg));
    seg = NextSeg(seg);
  }

  fn = NextFunction(0);
  while (fn != BADADDR) {
    fprintf(fh, "FUNC\t%s\t%s\t%s\t%s\n", hex(fn),
            hex(GetFunctionAttr(fn, FUNCATTR_END)),
            hex(GetFunctionAttr(fn, FUNCATTR_FLAGS)), GetFunctionName(fn));
    fn = NextFunction(fn);
  }

  nheads = 0;
  seg = FirstSeg();
  while (seg != BADADDR) {
    Message("export: segment %s\n", SegName(seg));
    segend = SegEnd(seg);
    ea = SegStart(seg);
    if (!isHead(GetFlags(ea)))
      ea = NextHead(ea, segend);
    while (ea != BADADDR && ea < segend) {
      f = GetFlags(ea);
      kind = "U";
      if (isCode(f)) kind = "C";
      else if (isData(f)) kind = "D";
      fprintf(fh, "HEAD\t%s\t%s\t%s\t%s\n", hex(ea), hex(ItemSize(ea)), kind,
              hex(f));
      nm = Name(ea);
      if (nm != "")
        fprintf(fh, "NAME\t%s\t%d\t%s\n", hex(ea), hasName(f), nm);
      cmt = Comment(ea);
      if (cmt != "")
        fprintf(fh, "CMT\t%s\t%s\n", hex(ea), clean(cmt));
      dump_xrefs(fh, ea);
      if (kind == "C")
        dump_ops(fh, ea, f);
      else if (kind == "D" && isOff0(f))
        fprintf(fh, "OP\t%s\t0\t5\t0\t1\t%s\n", hex(ea), clean(GetOpnd(ea, 0)));
      nheads = nheads + 1;
      ea = NextHead(ea, segend);
    }
    seg = NextSeg(seg);
  }

  fclose(fh);
  Message("export: wrote %d heads to %s\n", nheads, path);
}
