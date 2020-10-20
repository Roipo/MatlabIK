function LinkageDesign
close all;
myGui = gui.autogui('Location','float');
myGui.PanelWidth=200;
propsP = {'LineStyle','none','Marker','o','MarkerEdge','black','MarkerFaceColor','red','MarkerSize',6};
set(gcf,'Renderer','OpenGL');

warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
jFrame = get(handle(myGui.UiHandle),'JavaFrame'); drawnow;
jFrame_fHGxClient = jFrame.fHG2Client;
jFrame_fHGxClient.getWindow.setAlwaysOnTop(true);

axesopt={};

hFig = figure('WindowKeyPressFcn',@OnKeyPress);

MainAxes=axes('ButtonDownFcn',@OnLeftAxesDown); axis equal;
axis([-2,2,-2,2]);
linkage=Linkage(propsP{:});

addlistener(linkage,'PointPicked',@OnPPicked);

addlistener(linkage,'PointDropped',@OnPDropped);

addlistener(linkage,'PointDragged',@OnPointDrag);

addlistener(linkage,'PointRemoved',@OnPointRemoved);

%% Global variables
axes(MainAxes);

hold on
clickflag = false;

% Parameterizer=AutoCutsParameterizer;
% hLis=addlistener(Parameterizer,'IterationDone',@OnSolverIter);

active=false;
%% GUI initialization
BtnLoadSource = gui.pushbutton('Load Mesh');
BtnLoadSource.ValueChangedFcn = @OnButtonLoadMesh;


%% Callbacks
    function OnButtonLoadMesh(~)

    end
    function OnInitialize(~)
        Parameterizer.Initialize;
        EditMaxDist.Value = inf;
    end
    function OnPPicked(src,evt)

    end
    function OnPointDrag(~,~)

    end
    function OnPDropped(src,evt)
        
    end
    function OnPointRemoved(~,~)

    end
    function OnLeftAxesDown(src,evtdata)
        modifier = get(gcf,'SelectionType');
        pos=get(gca,'currentpoint'); pos=pos(1,1:2)';
        switch modifier
            case 'alt'  % in windows this is 'control'
                fi=linkage.AddPoint(pos);
            otherwise
                
            return;
        end
    end
    function OnKeyPress(src,evtdata)
        switch evtdata.Character
            case 's'
                if active==false
                    active=true;
                    Parameterizer.StartInteractiveDeform;
                else
                    active=false;
                    Parameterizer.StopInteractiveDeform;
                end
        end
    end
    function OnSolverIter(src,evtdata)
        Redraw;
    end

%% Helper Functions

%% Drawing functions
    function Redraw(~)
        drawnow;
    end
end