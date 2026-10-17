$controlsLibrary = Join-Path $PSScriptRoot 'ModernControls.dll'
if (Test-Path $controlsLibrary) {
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
    Add-Type -Path $controlsLibrary
    return
}
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing @'
using System.Drawing;
using System.Windows.Forms;
public class SmoothIndicatorPanel : Panel {
    public SmoothIndicatorPanel() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
    }
}
public class ThemedTrayRenderer : ToolStripSystemRenderer {
    public Color CheckColor { get; set; }
    protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e) {
        e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        var r=e.ImageRectangle;
        float x=r.Left+(r.Width-10)/2f, y=r.Top+(r.Height-8)/2f;
        using(var pen=new Pen(CheckColor,1.7f)) {
            pen.StartCap=System.Drawing.Drawing2D.LineCap.Round;
            pen.EndCap=System.Drawing.Drawing2D.LineCap.Round;
            e.Graphics.DrawLines(pen,new PointF[] {new PointF(x,y+4),new PointF(x+3,y+7),new PointF(x+10,y)});
        }
    }
}
public class ModernSettingsTabs : Panel {
    public class PageCollection : System.Collections.ObjectModel.Collection<Panel> {
        private ModernSettingsTabs owner;
        public PageCollection(ModernSettingsTabs value) { owner=value; }
        public void AddRange(Panel[] pages) { foreach (var page in pages) Add(page); }
        protected override void InsertItem(int index, Panel page) {
            base.InsertItem(index,page); owner.Controls.Add(page); owner.LayoutPages();
        }
    }
    public PageCollection TabPages { get; private set; }
    public Color BorderColor { get; set; }
    private int selectedIndex;
    public int SelectedIndex { get { return selectedIndex; } set { selectedIndex=value; LayoutPages(); Invalidate(); } }
    public ModernSettingsTabs() {
        TabPages=new PageCollection(this);
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
    }
    public void LayoutPages() {
        for(int i=0;i<TabPages.Count;i++) {
            TabPages[i].Bounds=new Rectangle(0,38,Width,Height-38);
            TabPages[i].Visible=i==selectedIndex;
        }
    }
    protected override void OnResize(System.EventArgs e) { base.OnResize(e); if(TabPages!=null) LayoutPages(); }
    protected override void OnMouseDown(MouseEventArgs e) {
        base.OnMouseDown(e);
        if(e.Y<36 && e.X/110<TabPages.Count) SelectedIndex=e.X/110;
    }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.Clear(BackColor);
        using(var pen=new Pen(BorderColor)) e.Graphics.DrawLine(pen,0,35,Width,35);
        for(int i=0;i<TabPages.Count;i++) {
            var rect=new Rectangle(i*110,0,110,34);
            TextRenderer.DrawText(e.Graphics,TabPages[i].Text,Font,rect,ForeColor,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter);
            if(i==selectedIndex) using(var pen=new Pen(ForeColor,2)) e.Graphics.DrawLine(pen,rect.Left+10,34,rect.Right-10,34);
        }
    }
}
public class ModernDeviceGroup : GroupBox {
    public Color BorderColor { get; set; }
    public ModernDeviceGroup() {
        SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
    }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.Clear(BackColor);
        Size size = TextRenderer.MeasureText(Text, Font);
        using (var pen = new Pen(BorderColor)) {
            e.Graphics.DrawRectangle(pen, 0, size.Height/2, Width-1, Height-size.Height/2-1);
        }
        using (var brush = new SolidBrush(BackColor))
            e.Graphics.FillRectangle(brush, 8, 0, size.Width+4, size.Height);
        TextRenderer.DrawText(e.Graphics, Text, Font, new Point(10,0), ForeColor);
    }
}
public class SoftButton : Button {
    public SoftButton() { SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true); }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        e.Graphics.PixelOffsetMode=System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
        e.Graphics.Clear(Parent!=null ? Parent.BackColor : BackColor);
        using(var path=new System.Drawing.Drawing2D.GraphicsPath()) {
            float inset=System.Math.Max(0.5f,FlatAppearance.BorderSize/2f);
            float r=12, w=Width-2*inset, h=Height-2*inset;
            path.AddArc(inset,inset,r,r,180,90); path.AddArc(inset+w-r,inset,r,r,270,90);
            path.AddArc(inset+w-r,inset+h-r,r,r,0,90); path.AddArc(inset,inset+h-r,r,r,90,90); path.CloseFigure();
            using(var brush=new SolidBrush(BackColor)) e.Graphics.FillPath(brush,path);
            var state=e.Graphics.Save(); e.Graphics.SetClip(path);
            if(BackgroundImage!=null) e.Graphics.DrawImage(BackgroundImage,0,0,Width,Height);
            e.Graphics.Restore(state);
            int width=FlatAppearance.BorderSize;
            if(width>0) using(var pen=new Pen(FlatAppearance.BorderColor,width)) { pen.Alignment=System.Drawing.Drawing2D.PenAlignment.Center; e.Graphics.DrawPath(pen,path); }
            var textRect=ClientRectangle;
            if(TextAlign==ContentAlignment.BottomCenter) textRect=new Rectangle(6,59,Width-12,Height-65);
            TextRenderer.DrawText(e.Graphics,Text,Font,textRect,Enabled?ForeColor:SystemColors.GrayText,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.WordBreak);
            if(Focused && ShowFocusCues) ControlPaint.DrawFocusRectangle(e.Graphics,new Rectangle(5,5,Width-10,Height-10),ForeColor,BackColor);
        }
    }
}
public class SoftComboBox : ComboBox {
    public SoftComboBox() { DrawMode=DrawMode.OwnerDrawFixed; ItemHeight=24; FlatStyle=FlatStyle.Flat; }
    protected override void OnDrawItem(DrawItemEventArgs e) {
        Color bg=(e.State & DrawItemState.Selected)!=0 && (e.State & DrawItemState.ComboBoxEdit)==0 ? ControlPaint.Light(BackColor) : BackColor;
        using(var brush=new SolidBrush(bg)) e.Graphics.FillRectangle(brush,e.Bounds);
        if(e.Index>=0) {
            var rect=e.Bounds; rect.X+=7; rect.Width-=7;
            TextRenderer.DrawText(e.Graphics,GetItemText(Items[e.Index]),Font,rect,ForeColor,TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
        }
    }
}
'@
