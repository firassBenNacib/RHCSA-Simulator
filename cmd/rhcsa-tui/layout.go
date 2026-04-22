package main

import "strings"

const (
	minWideLayoutWidth    = 100
	minWideLayoutHeight   = 24
	maxStatusHeight       = 12
	minStatusHeight       = 4
	chromeHeight          = 4
	minContentHeight      = 4
	minDetailTextWidth    = 20
	listPaneBorder        = 3
	detailPaneBorder      = 5
	defaultMaxStatusLines = 10
)

func (m model) useStackedLayout() bool {
	return m.width < minWideLayoutWidth || m.height < minWideLayoutHeight
}

func clampInt(value, low, high int) int {
	if high < low {
		return low
	}
	return min(max(value, low), high)
}

func (m model) listPaneWidth() int {
	if m.useStackedLayout() {
		return m.width
	}
	preferred := max((m.width*37)/100, 32)
	return min(preferred, max(m.width-44, 32))
}

func (m model) detailPaneWidth() int {
	if m.useStackedLayout() {
		return m.width
	}
	return max(m.width-m.listPaneWidth()-1, minDetailTextWidth)
}

func (m model) detailPaneOrigin() (int, int) {
	contentY := 2
	if m.useStackedLayout() {
		return 0, contentY + m.listPaneHeight() + 1
	}
	return m.listPaneWidth() + 1, contentY
}

func (m model) detailTextWidth() int {
	if m.useStackedLayout() {
		return max(m.width-detailPaneBorder, minDetailTextWidth)
	}
	return max(m.detailPaneWidth()-detailPaneBorder, minDetailTextWidth)
}

func (m model) statusPaneHeight() int {
	if m.filterMode {
		return 0
	}
	if strings.TrimSpace(m.statusText) == "" && !m.busy && !m.filterMode && m.confirmKind == "" {
		return 0
	}

	lineCount := len(strings.Split(strings.TrimSpace(m.statusBody()), "\n"))
	if lineCount < 1 {
		lineCount = 1
	}

	desired := lineCount + 4
	maxAllowed := max(m.height/3, minStatusHeight)
	if maxAllowed > maxStatusHeight {
		maxAllowed = maxStatusHeight
	}
	desired = clampInt(desired, minStatusHeight, maxAllowed)
	return desired
}

func (m model) contentHeight() int {
	h := m.height - chromeHeight - m.statusPaneHeight()
	if m.filterMode {
		h--
	}
	return max(h, minContentHeight)
}

func (m model) listPaneHeight() int {
	ch := m.contentHeight()
	if m.useStackedLayout() {
		return max(ch/3, 6)
	}
	return ch
}

func (m model) detailPaneHeight() int {
	ch := m.contentHeight()
	if m.useStackedLayout() {
		return max(ch-m.listPaneHeight(), 6)
	}
	return ch
}

func (m model) listPageSize() int {
	return max(m.listPaneHeight()-2, 1)
}

func (m model) visibleRange(total int) (int, int) {
	pageSize := m.listPageSize()
	start := clampInt(m.listOffset, 0, max(total-pageSize, 0))
	end := start + pageSize
	if end > total {
		end = total
	}
	return start, end
}

func (m model) detailVisibleLines() int {
	return max(m.detailPaneHeight()-detailPaneBorder, 1)
}

func (m model) detailPageStep() int {
	return max(m.detailVisibleLines()-3, 1)
}

func (m model) detailMaxOffset() int {
	lines := strings.Split(m.renderDetailBody(), "\n")
	return max(len(lines)-m.detailVisibleLines(), 0)
}

func (m model) currentDetailOffset() int {
	return m.detailOffsets[m.detail]
}

func (m *model) setCurrentDetailOffset(offset int) {
	m.detailOffsets[m.detail] = clampInt(offset, 0, m.detailMaxOffset())
}

func (m *model) resetDetailOffsets() {
	for i := range m.detailOffsets {
		m.detailOffsets[i] = 0
	}
}

func (m model) nextDetailSectionOffset() int {
	offsets := m.detailSectionOffsets()
	current := m.currentDetailOffset()
	for _, offset := range offsets {
		if offset > current {
			return offset
		}
	}
	return m.detailMaxOffset()
}

func (m model) previousDetailSectionOffset() int {
	offsets := m.detailSectionOffsets()
	current := m.currentDetailOffset()
	prev := 0
	for _, offset := range offsets {
		if offset >= current {
			break
		}
		prev = offset
	}
	return prev
}

func (m *model) adjustListOffset() {
	pageSize := m.listPageSize()
	if pageSize < 1 {
		return
	}

	selected := m.selectedExam
	total := len(m.filteredExams())
	if m.activeTab == labsTab {
		selected = m.selectedLab
		total = len(m.filteredLabs())
	}

	if selected < m.listOffset {
		m.listOffset = selected
	}
	if selected >= m.listOffset+pageSize {
		m.listOffset = selected - pageSize + 1
	}
	m.listOffset = clampInt(m.listOffset, 0, max(total-pageSize, 0))
}
